// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import 'hardhat/console.sol';

/* Inheritance tree
   A
 /  \
B   C
 \ /
  D
*/

contract A {
  // This is called an event. You can emit events from your function
  // and they are logged into the transaction log.
  // In our case, this will be useful for tracing function calls.
  event Log(string message);

  function foo() public virtual {
    console.log('A.foo called');
  }

  function bar() public virtual {
    console.log('A.bar called');
  }
}

contract B is A {
  function foo() public virtual override {
    console.log('B.foo called');
    A.foo();
  }

  function bar() public virtual override {
    console.log('B.bar called');
    A.bar();
  }
}

contract C is A {
  function foo() public virtual override {
    console.log('C.foo called');
    A.foo();
  }

  function bar() public virtual override {
    console.log('C.bar called');
    super.bar();
  }
}

contract D is B, C {
  // Try:
  // - Call D.foo and check the transaction logs.
  //   Although D inherits A, B and C, it only called C and then A.
  // - Call D.bar and check the transaction logs
  //   D called C, then B, and finally A.
  //   Although super was called twice (by B and C) it only called A once.

  function foo() public override(B, C) {
    super.foo();
  }

  function bar() public override(B, C) {
    super.bar();
  }
}
