// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract DataStorage {
    // The data location of x is storage.
    // This is the only place where the
    // data location can be omitted.
    uint[] public data = [1,2,3];

    function modifyStorageData() public {
        // Declaring a storage variable dataStorage, pointing to data.
        // Modifying dataStorage will also affect data.
        uint[] storage dataStorage = data;
        dataStorage[0] = 100;
    }

    function modifyMemoryData() public view {
        // Declaring a memory variable dataMemory, copying data.
        // Modifying dataMemory will not affect data.
        uint[] memory dataMemory = data;
        dataMemory[0] = 100;
        dataMemory[1] = 200;
        uint[] memory dataMemory2 = data;
        dataMemory2[0] = 300;
    }

    function returnCalldata(uint[] calldata _data) public pure returns(uint[] calldata) {
        // Parameter is a calldata array, cannot be modified.
        // _data[0] = 0 // Modifying like this will result in an error.
        return(_data);
    }
}

contract Variables {
    uint public a = 1;
    uint public b;
    string public c;

    function changeStateVariables() external {
        // Modifying state variables' values within a function is allowed.
        a = 5;
        b = 2;
        c = "0xAA";
    }

    function calculate() external pure returns(uint) {
        uint x = 1;
        uint y = 3;
        uint z = x + y;
        return z;
    }

    function globalVariables() external view returns(address, uint, bytes memory) {
        address sender = msg.sender;
        uint blockNumber = block.number;
        bytes memory data = msg.data;
        return(sender, blockNumber, data);
    }

    function weiUnit() external pure returns(uint) {
        assert(1 wei == 1);
        return 1 wei;
    }

    function gweiUnit() external pure returns(uint) {
        assert(1 gwei == 1000000000);
        return 1 gwei;
    }

    function etherUnit() external pure returns(uint) {
        assert(1 ether == 1000000000000000000);
        return 1 ether;
    }
    
    function secondsUnit() external pure returns(uint) {
        assert(1 seconds == 1);
        return 1 seconds;
    }

    function minutesUnit() external pure returns(uint) {
        assert(1 minutes == 60);
        return 1 minutes;
    }

    function hoursUnit() external pure returns(uint) {
        assert(1 hours == 3600);
        return 1 hours;
    }

    function daysUnit() external pure returns(uint) {
        assert(1 days == 86400);
        return 1 days;
    }

    function weeksUnit() external pure returns(uint) {
        assert(1 weeks == 604800);
        return 1 weeks;
    }
}
