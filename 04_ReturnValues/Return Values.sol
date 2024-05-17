// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Returning multiple values
// Named return values
// Destructuring assignment

contract ReturnValue {
    // Return multiple values
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
        return (1, true, [uint256(1), 2, 5]);
    }

    // Named return values
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        _number = 2;
        _bool = false; 
        _array = [uint256(3), 2, 1];
    }

    // Named return values with 'return' keyword
    function returnNamed2() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        return (1, true, [uint256(1), 2, 5]);
    }

    // Read returned values using destructuring assignment
    function readReturn() public pure{
        // Read all returned values
        uint256 _number;
        bool _bool;
        bool _bool2;
        uint256[3] memory _array;
        (_number, _bool, _array) = returnNamed();
        
        // Read partial returned values using destructuring assignment
        (, _bool2, ) = returnNamed();
        
    }

    // Function to demonstrate usage of returned values
    function useReturnedValues() public pure returns(uint256, bool) {
        // Calling returnMultiple and storing returned values
        (uint256 num, bool flag, uint256[3] memory arr) = returnMultiple();
        
        // Using the returned values
        uint256 sum = num + arr[0]; // Sum of the first returned number and the first element of the array
        bool oppositeFlag = !flag; // Getting the opposite boolean value of the second returned value
        
        return (sum, oppositeFlag);
    }
}
