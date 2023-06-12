// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import { CommonBase } from "forge-std/Base.sol";
import "forge-std/console.sol";

/* 
  Make arbitrary delegatecalls to an implementation contract.

  Supplements vm.prank.

  You already know how to make a contract c call dest.fn(args):

    vm.prank(c);
    dest.fn(args);

  Now, to make c delegatecall dest.fn(args):

    delegatePrank(c,address(dest),abi.encodeCall(fn,(args)));

*/
contract DelegatePrank is CommonBase {
  bytes delegatorCode = makeDelegatorCode();
  bytes latestCode;
  // Generate the code with which we will temporarily replace the contract to delegateprank.
  function makeDelegatorCode() internal returns (bytes memory) {
    return address(new Delegator()).code;
  }

  // Etch saved code to sender. Done through storage instead of function arguments to avoid polluting forge trace.
  function etchLatestCodeToSender() external {
    vm.etch(msg.sender,latestCode);
  }

  function delegatePrank(address from, address to, bytes memory cd) public returns (bool success, bytes memory ret) {
    latestCode = from.code;
    vm.etch(from,delegatorCode);
    (success, ret) = from.call(abi.encodeCall(Delegator.etchCodeAndDelegateCall,(to,cd)));
  }
}

contract Delegator is CommonBase {

  DelegatePrank immutable delegatePranker = DelegatePrank(msg.sender);

  function etchCodeAndDelegateCall(address dest, bytes memory cd) external payable virtual {
    /* At this point address(this) has the code of Delegator, but needs to be etched with its former code. But rules on cheatcode access for forked contracts make it unable to call vm.etch on itself.

    The clean solution would be to allow cheatcodes to address(this), have it self-etch the new code, then disallow cheatcodes again (otherwise there is a divergence between interpreter state locally and onchain). But there is no vm.disallowCheatcodes cheatcode yet. 
    
    Until then we do an ugly hack: call the test contract, which etches the code to address(this), then revert to the current context. At this point the execution continues with the _old_ code.*/
    delegatePranker.etchLatestCodeToSender();
    assembly ("memory-safe") {
      let result := delegatecall(gas(), dest, add(cd,32), mload(cd), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}
