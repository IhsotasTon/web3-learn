// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;
import 'hardhat/console.sol';

contract C {
  // The data location of x is storage.
  // This is the only place where the
  // data location can be omitted.
  uint256[] x;

  // The data location of memoryArray is memory.
  function f(uint256[] memory memoryArray) public {
    x = memoryArray; // memory => storage 是值传递
    uint256[] storage y = x; // storage => local storage 是引用
    y[7]; // fine, returns the 8th element
    y.pop(); // 因为是引用所以改变了x
    delete x; // 可以把x的所有元素改为0
    //已经指向x了,不可改变y
    // y = memoryArray;
    //不能通过指针重置x
    // delete y;
    g(x); // 函数的参数也算是local storage，所以storage => local storage是引用传递
    h(x); // storage => memory是值传递
  }

  function g(uint256[] storage) internal pure {}

  function h(uint256[] memory) public pure {}
}
