// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {DelegatePrank} from "src/DelegatePrank.sol";

contract Counter {
  uint256 public number;

  function setNumber(uint256 newNumber) public {
    number = newNumber;
  }

  function returnSender() public view returns (address) {
    return msg.sender;
  }

  function dynamicArray(uint length) public pure returns (uint[] memory) {
    uint[] memory ret = new uint[](length);
    for (uint i = 0;i<length;i++) {
      ret[i]=i;
    }
    return ret;
  }

  function fail() public pure {
    assert(false);
  }
}

contract CounterTest is Test, DelegatePrank {
  Counter public counter;
  Counter public counter2;

  // NOT TESTED:
  // - That this works in forking mode. In particular that existing contracts being delegatepranked do not fail because e.g. they need cheatcode access. I don't know how to test forking mode internally (ie just through forge tests without an external process).

  function setUp() public {
    counter = new Counter();
    counter2 = new Counter();

    counter.setNumber(3);
  }

  function testDelegation(uint256 x) public {
    delegatePrank(address(counter),address(counter2),abi.encodeCall(counter2.setNumber,(x)));
    assertEq(counter.number(),x);
  }

  function testReentrancy(uint256 x) public {
    delegatePrank(address(counter),address(counter),abi.encodeCall(counter.setNumber,(x)));
    assertEq(counter.number(), x);
  }

  function testReturnDataUint(uint256 x) public {
    counter.setNumber(x);
    (,bytes memory ret) = delegatePrank(address(counter),address(counter),abi.encodeCall(counter.number,()));
    uint y = abi.decode(ret,(uint));
    assertEq(y,x);
  }

  function testReturnDataArray(uint length) public {
    length = bound(length,0,10);
    (bool success, bytes memory ret) = delegatePrank(address(counter),address(counter),abi.encodeCall(counter.dynamicArray,(length)));
    assertEq(success,true);
    uint[] memory array = abi.decode(ret,(uint[]));

    for (uint i = 0;i<length;i++) {
      assertEq(array[i],i);
    }
  }

  function testRevert() public {
    (bool success, bytes memory ret) = delegatePrank(address(counter),address(counter),abi.encodeCall(counter.fail,()));
    assertEq(success,false);
    assertEq(ret,stdError.assertionError);
  }

  function testPrank(address orig) public {
    vm.prank(orig);
    (bool success, bytes memory ret) = delegatePrank(address(counter),address(counter),abi.encodeCall(counter.returnSender,()));
    assertEq(success, true);
    assertEq(abi.decode(ret,(address)),orig);
  }
}
