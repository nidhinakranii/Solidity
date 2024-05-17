// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Owner {
   address public owner; // Define owner variable

   // Constructor
   constructor(address initialOwner) {
      owner = initialOwner; // Set owner to the initialOwner address when deploying the contract
   }

   // Define modifier
   modifier onlyOwner {
      require(msg.sender == owner); // Check if the caller is the owner address
      _; // Continue executing the function body if true; otherwise, revert the transaction
   }

   // Define a function with the onlyOwner modifier
   function changeOwner(address _newOwner) external onlyOwner {
      owner = _newOwner; // Change the owner only if called by the owner address
   }
}
