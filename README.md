# Delegatecall from any contract. 

Make arbitrary delegatecalls to an implementation contract.

Supplements `vm.prank`.

### Install:

```
$ forge install adhusson/delegate-prank
```

### How to use:

You already know how to make an address  `c` call `dest.fn(args)`:

```solidity
vm.prank(c);
dest.fn(args);
```

Now you can make `c` delegatecall `dest.fn(args)`:

```solidity
delegatePrank(c,address(dest),abi.encodeCall(fn,(args)));
```

It works by swapping the bytecode of the pranked address with a delegator contract.

Cool things:
* The bytecode is swapped back on the fly, so you can never tell your bytecode got changed. This means reentrancy works.
* You can still `vm.prank` before using `delegatePrank`

### In-context example

```solidity
import {DelegatePrank} from "delegate-prank/DelegatePrank.sol";

contract MyTest is Test, DelegatePrank {

  function test_one() public {
    bytes memory cd = abi.encodeCall(spell.execute,());
    delegatePrank(multisig,spell,cd);
  }

}
```

#### Notes
Thanks to @ckksec for the idea of [restoring the bytecode automatically](https://github.com/foundry-rs/foundry/issues/824#issuecomment-1490860555)!