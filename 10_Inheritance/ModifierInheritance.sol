// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Base {
    // Modifier to ensure the given number is exactly divisible by 2 and 3
    modifier exactDividedBy2And3(uint _a) virtual {
        require(_a % 2 == 0 && _a % 3 == 0, "Number must be exactly divisible by 2 and 3");
        _;
    }
}

contract NumberIdentifier is Base {

    // Function to compute the values obtained by dividing a number by 2 and 3, given that the number is divisible by both
    function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
        return getExactDividedBy2And3WithoutModifier(_dividend);
    }

    // Function to compute the values obtained by dividing a number by 2 and 3
    function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
        uint div2 = _dividend / 2;
        uint div3 = _dividend / 3;
        return (div2, div3);
    }

    // Overriding the modifier to allow divisibility check for 2 and 3
    modifier exactDividedBy2And3(uint _a) override {
        require(_a % 2 == 0 && _a % 3 == 0, "Number must be exactly divisible by 2 and 3");
        _;
    }
}
