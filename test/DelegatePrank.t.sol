// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import { DelegatePrank, Delegator } from "../src/DelegatePrank.sol";

contract Counter {
  uint256 public number;
  uint256 public number2;

  function setNumber(uint256 newNumber) public {
    number = newNumber;
  }

  function setNumber2(uint256 newNumber) public {
    number2 = newNumber;
  }

  function increment() public {
    number++;
  }

  function increment2() public {
    number2++;
  }
}

contract CounterTest is Test, DelegatePrank {
  Counter public counter;
  Counter public counter2;

  function setUp() public {
    counter = new Counter();
    counter2 = new Counter();

    counter.setNumber(3);
  }

  function testInit() public {
    addDelegation(address(counter));
    assertEq(counter.number(), 3);
  }

  function testIncrement() public {
    addDelegation(address(counter));
    counter.increment();
    assertEq(counter.number(), 4);
  }

  function testSetNumber(uint256 x) public {
    addDelegation(address(counter));
    counter.setNumber(x);
    assertEq(counter.number(), x);
  }

  function testDelegation(uint256 x) public {
    Delegator d = addDelegation(address(counter));
    d.delegatecall(address(counter2), abi.encodeCall(counter2.setNumber2, (x)));
    assertEq(counter.number2(), x);
  }
}
