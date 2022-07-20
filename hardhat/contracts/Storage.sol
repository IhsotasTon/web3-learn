// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import 'hardhat/console.sol';

contract Storage {
  // The data location of x is storage.
  // This is the only place where the
  // data location can be omitted.
  uint256[] x = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  uint256[] y = x;
  struct a {
    int256 i;
    int256 j;
  }

  function getX() public view returns (uint256[] memory) {
    return x;
  }

  function getY() public view returns (uint256[] memory) {
    return y;
  }

  // The data location of memoryArray is memory.
  function f(uint256[] memory arr) public {
    y.pop();
    arr = x;
  }

  function local2local() public {
    uint256[] storage a = x;
    uint256[] storage b = a;
    b.pop();
  }
}
