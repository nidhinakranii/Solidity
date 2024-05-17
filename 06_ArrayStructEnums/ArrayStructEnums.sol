// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract ArrayTypes {

    // Fixed-length Array
    uint[8] public fixedArray;
    bytes1[5] public fixedByteArray;
    address[100] public fixedAddressArray;

    // Dynamic-length Array
    uint[] public dynamicArray;
    bytes1[] public dynamicByteArray;
    address[] public dynamicAddressArray;
    bytes public byteArray;

    // Initializing Dynamic Array
    uint[] public initializedDynamicArray = new uint[](5);
    bytes public initializedByteArray = new bytes(9);

    // Function to initialize a dynamic array
    function initializeArray() external pure returns(uint[] memory) {
        uint[] memory x = new uint[](3);
        x[0] = 1;
        x[1] = 3;
        x[2] = 4;
        return x;
    }  

    // Function to push an element into a dynamic array
    function pushToArray() public returns(uint[] memory) {
        uint[2] memory a = [uint(1), 2];
        dynamicArray = a;
        dynamicArray.push(3);
        return dynamicArray;
    }
}

contract StructTypes {
    // Struct Definition
    struct Student {
        uint256 id;
        uint256 score; 
    }
    Student public student;

    // Function to initialize struct - Method 1: Using a storage reference in a function
    function initStudent1() external {
        Student storage _student = student; // assign a copy of student
        _student.id = 11;
        _student.score = 100;
    }

    // Function to initialize struct - Method 2: Directly using the state variable
    function initStudent2() external {
        student.id = 1;
        student.score = 80;
    }
    
    // Function to initialize struct - Method 3: Constructor-style initialization
    function initStudent3() external {
        student = Student(3, 90);
    }

    // Function to initialize struct - Method 4: Key-value pair initialization
    function initStudent4() external {
        student = Student({id: 4, score: 60});
    }
}

contract EnumTypes {
    // Enum Definition
    enum ActionSet { Buy, Hold, Sell }

    // Enum variable
    ActionSet public action = ActionSet.Buy;

    // Function to convert enum to uint
    function enumToUint() external view returns(uint) {
        return uint(action);
    }
}
