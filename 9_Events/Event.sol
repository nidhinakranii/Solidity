// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Events {
    // Define the _balances mapping variable to record the balance of each address
    mapping(address => uint256) public _balances;

    // Define the Transfer event to record the transfer transaction's sender, receiver, and amount
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Define the _transfer function to execute the transfer logic
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) external {

        _balances[from] = 100; // Provide some initial tokens to the sender address

        _balances[from] -=  amount; // Subtract the amount from the sender's address
        _balances[to] += amount; // Add the amount to the receiver's address

        // Emit the Transfer event
        emit Transfer(from, to, amount);
    }
}
