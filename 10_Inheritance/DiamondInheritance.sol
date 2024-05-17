// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Base contract defining common functionality
contract FinancialEntity {
    event Log(string message);

    function deposit() public virtual {
        emit Log("FinancialEntity.deposit called");
    }

    function withdraw() public virtual {
        emit Log("FinancialEntity.withdraw called");
    }
}

// Sub-contract representing a bank
contract Bank is FinancialEntity {
    function deposit() public virtual override {
        emit Log("Bank.deposit called");
        super.deposit();
    }

    function withdraw() public virtual override {
        emit Log("Bank.withdraw called");
        super.withdraw();
    }
}

// Sub-contract representing a credit union
contract CreditUnion is FinancialEntity {
    function deposit() public virtual override {
        emit Log("CreditUnion.deposit called");
        super.deposit();
    }

    function withdraw() public virtual override {
        emit Log("CreditUnion.withdraw called");
        super.withdraw();
    }
}

// Sub-contract representing account holders
contract AccountHolders is Bank, CreditUnion {
    function deposit() public override(Bank, CreditUnion) {
        super.deposit();
    }

    function withdraw() public override(Bank, CreditUnion) {
        super.withdraw();
    }
}
