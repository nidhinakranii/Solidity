// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Mapping {
    mapping(uint => address) public idToAddress; // Mapping from ID to address
    mapping(address => address) public swapPair; // Mapping of pairs, address to address

    function writeMap (uint _Key, address _Value) public {
        idToAddress[_Key] = _Value;
    }
}
