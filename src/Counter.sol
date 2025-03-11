// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    event CounterChanged(uint256 indexed newNumber);

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit CounterChanged(newNumber);
    }

    function increment() public {
        number++;
        emit CounterChanged(number);
    }
}
