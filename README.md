# Delegatecall from any contract. 

A kind of vm.prank for delegatecalls. For when you want to make an existing contract execute arbitrary code (a multisig, for instance).

### Install:

```
$ forge install adhusson/delegate-prank
```

### Use in tests:

```solidity
import {DelegatePrank} from "delegate-prank/DelegatePrank.sol";

contract MyTest is Test, DelegatePrank {
  // ...
  function test_one() public {
    Spell spell = new Spell();
    Delegator d = addDelegation(address(ms));
    // ms will delegatecall to spell 
    d.delegatecall(spell,abi.encodeCall(spell.execute,()));
  }
}

contract Spell {
  function execute() {
    // ...
  }
}
```
