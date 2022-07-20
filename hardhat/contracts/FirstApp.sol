// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
contract Counter {
  uint public count;
  function get() public view returns (uint){
    return count;
  }

  function inc() public {
    count +=1;
  }
  function dec() public {
    console.log(count);
    count -=1;
  }
}