// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import { CommonBase } from "../lib/forge-std/src/Base.sol";

/* 
  Make arbitrary delegatecalls from an implementation contract.

  Supplements vm.prank.

  You already know how to make a contract c do arbitrary calls: 

    vm.prank(address(c));
    dest.function(args);

  Now, to make c do arbitrary delegatecalls:

    Delegator d = addDelegation(address(c));
    d.delegatecall(dest,abi.encodeCall(dest.function,(args))).

  You can also ignore the return value of addDelegation and convert c later:

    addDelegation(address(c));
    Delegator d = Delegator(payable(address(c)));
    d.delegatecall(dest,abi.encodeCall(dest.function,(args))).

  Caveats:
  * Increased gas used (take it into account in your measurements).
  * Delegator's delegatecall(address,bytes) will shadow that same function at implementation.
  * As always be careful about storage slot overlap.*/
contract DelegatePrank is CommonBase {
  function addDelegation(address original) internal virtual returns (Delegator) {
    vm.etch(nextAddress(original), original.code);
    vm.etch(original, vm.getDeployedCode("DelegatePrank.sol:Delegator"));
    return Delegator(payable(original));
  }
}

contract Delegator {
  function delegatecall(address dest, bytes calldata cd) external payable virtual {
    proxyTo(dest, cd);
  }

  fallback() external payable virtual {
    proxyTo(nextAddress(address(this)), msg.data);
  }

  receive() external payable virtual {
    proxyTo(nextAddress(address(this)), new bytes(0));
  }

  function proxyTo(address dest, bytes memory cd) internal {
    assembly {
      let result := delegatecall(gas(), dest, add(cd, 32), mload(cd), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}

// shared utility
function nextAddress(address addr) pure returns (address) {
  return address(uint160(addr) + 1);
}
