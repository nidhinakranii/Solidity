// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract FunctionTypes {
    uint256 public value = 5;
    
    constructor() payable {}

    // Function types
    // function (<parameter types>) {internal|external} [pure|view|payable] [returns (<return types>)]
    // Default function
    function increment() external {
        value = value + 1;
    }

    // pure: Does not read or modify state
    function incrementPure(uint256 _value) external pure returns (uint256 newValue) {
        newValue = _value + 1;
    }
    
    // view: Reads state but does not modify it
    function incrementView() external view returns (uint256 newValue) {
        newValue = value + 1;
    }

    // internal: Can only be called within the contract
    function decrement() internal {
        value = value - 1;
    }

    // Internal function can be called within other contract functions
    function callDecrement() external {
        decrement();
    }

    // payable: Function that can receive ETH
    function decrementPayable() external payable returns (uint256 contractBalance) {
        decrement();    
        contractBalance = address(this).balance;
    }
}
