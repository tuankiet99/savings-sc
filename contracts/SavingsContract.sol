// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SavingsContract is Ownable {
    struct Saving {
        uint amount;
        uint depositTime;
        uint term; // Thời hạn gửi tiền (số tháng)
    }

    mapping(address => Saving[]) public savings;
    uint public interestRate6Months = 3; // Lãi suất 6 tháng (%)
    uint public interestRate12Months = 4; // Lãi suất 12 tháng (%)
    uint public balance;

    constructor() payable Ownable(msg.sender) {
        // Thêm tiền vào địa chỉ SC khi SC được khởi tạo
        balance = msg.value;
    }

    function deposit(uint _amount, uint _term) external payable {
        require(_amount >= 10, "Minimum deposit amount is 10 tokens.");
        require(_term == 6 || _term == 12, "Invalid term.");

        balance += _amount;
        savings[msg.sender].push(
            Saving({amount: _amount, term: _term, depositTime: block.timestamp})
        );
    }

    function withdraw(uint _savingIndex) external {
        require(
            _savingIndex < savings[msg.sender].length,
            "Invalid saving index."
        );

        Saving storage saving = savings[msg.sender][_savingIndex];

        require(
            block.timestamp >= saving.depositTime + saving.term * 30 days,
            "The term has not expired yet."
        );

        uint interestRate;
        // Kiểm tra kỳ hạn của khoản tiết kiệm là 6 tháng hay 12 tháng để xác định lãi suất áp dụng.
        if (saving.term == 6) {
            interestRate = interestRate6Months;
        } else if (saving.term == 12) {
            interestRate = interestRate12Months;
        }
        uint interest = calculateInterest(
            interestRate,
            saving.amount,
            block.timestamp - saving.depositTime
        );
        uint totalAmount = saving.amount + interest;
        // Kiểm tra tiền trong SC đủ để dư để thanh toán cho user không
        require(
            address(this).balance >= totalAmount,
            "Insufficient contract balance."
        );
        delete savings[msg.sender][_savingIndex];
        payable(msg.sender).transfer(totalAmount);

        balance -= totalAmount;
    }

    function withdrawForAdmin(
        address payable _to,
        uint _amount
    ) external onlyOwner {
        require(
            address(this).balance >= _amount,
            "Insufficient contract balance."
        );
        _to.transfer(_amount);

        balance -= _amount;
    }

    function getBalance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function setInterestRate(
        uint _interestRate6Months,
        uint _interestRate12Months
    ) external onlyOwner {
        interestRate6Months = _interestRate6Months;
        interestRate12Months = _interestRate12Months;
    }

    function calculateInterest(
        uint _interestRate,
        uint _amount,
        uint _elapsedTime
    ) internal pure returns (uint) {
        uint annualInterest = (_amount * uint(_interestRate)) / 100;
        uint interest = (_elapsedTime * annualInterest) / 365 days;
        return interest;
    }
}
