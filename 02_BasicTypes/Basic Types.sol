// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract BasicTypes {
    // Boolean values and logical operations
    bool public flag = true;
    bool public flag1 = !flag; // Logical NOT: false
    bool public flag2 = flag && flag1; // Logical AND: false
    bool public flag3 = flag || flag1; // Logical OR: true
    bool public flag4 = flag == flag1; // Equality check: false
    bool public flag5 = flag != flag1; // Inequality check: true

    // Integer and unsigned integer
    int public negativeNumber = -1; // Signed integer
    uint public positiveNumber = 1; // Unsigned integer
    uint256 public largeNumber = 20220330; // Unsigned integer (256 bits)

    // Arithmetic operations on unsigned integers
    uint256 public incrementedNumber = largeNumber + 1; // Increment largeNumber by 1
    uint256 public exponentiation = 2**2; // 2 raised to the power of 2
    uint256 public remainder = 7 % 2; // Modulus: remainder of 7 divided by 2 (1)
    bool public comparisonResult = exponentiation > remainder; // Comparison: true

    // Address and payable address
    address public sampleAddress = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB; // Regular Ethereum address
    address payable public payableAddress = payable(sampleAddress); // Payable address, allows sending/receiving Ether

    // Get the balance of the payable address
    uint256 public balanceOfPayableAddress = payableAddress.balance; // Balance of payableAddress in wei

    // Byte types and operations
    bytes32 public byteData = "BlockchainTech"; // Fixed-size byte array (32 bytes)
    bytes1 public firstByte = byteData[0]; // First byte of byteData

    // Enum definition and usage
    enum TradeAction { Buy, Hold, Sell }
    TradeAction public tradeAction = TradeAction.Buy; // Enum variable set to 'Buy'

    // Function to return the integer representation of the enum value
    function getTradeAction() external view returns (uint) {
        return uint(tradeAction); // Convert enum value to uint and return
    }
}
