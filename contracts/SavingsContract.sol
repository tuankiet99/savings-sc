// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // chống kẻ tấn công thực thi func nhiều lần trước khi lệnh gọi trước đó hoàn thành

contract SavingsContract is Ownable, ReentrancyGuard {
    struct Saving {
        uint amount;
        uint depositTime;
        uint term; // Thời hạn gửi tiền (số tháng)
        uint interestRate; // Lãi suất tại thời điểm gửi tiền
    }

    mapping(address => Saving[]) public savings;
    uint public interestRate6Months = 3; // Lãi suất 6 tháng (%)
    uint public interestRate12Months = 4; // Lãi suất 12 tháng (%)

    constructor() payable Ownable(msg.sender) {}

    /**
     * File js test can not access from mapping variable
     * So, create this function to access from test file js
     */
    function getUserSaving(
        address user,
        uint index
    ) public view returns (uint, uint, uint) {
        Saving storage saving = savings[user][index];
        return (saving.amount, saving.depositTime, saving.term);
    }

    function deposit(uint _term) external payable {
        uint interestRate;
        if (_term == 6) {
            interestRate = interestRate6Months;
        } else if (_term == 12) {
            interestRate = interestRate12Months;
        } else {
            revert("Invalid term.");
        }

        savings[msg.sender].push(
            Saving({
                amount: msg.value,
                term: _term,
                depositTime: block.timestamp,
                interestRate: interestRate
            })
        );
    }

    function withdraw(uint _savingIndex) external nonReentrant {
        require(
            _savingIndex < savings[msg.sender].length,
            "Invalid saving index."
        );

        Saving storage saving = savings[msg.sender][_savingIndex];

        require(
            block.timestamp >= saving.depositTime + (saving.term * 30 days),
            "The term has not expired yet."
        );

        uint interest = calculateInterest(
            saving.interestRate,
            saving.amount,
            block.timestamp - saving.depositTime
        );
        uint totalAmount = saving.amount + interest;

        require(
            address(this).balance >= totalAmount,
            "Insufficient contract balance."
        );

        delete savings[msg.sender][_savingIndex];

        payable(msg.sender).transfer(totalAmount);
    }

    function withdrawForAdmin(
        address payable _to,
        uint _amount
    ) external onlyOwner nonReentrant {
        require(
            address(this).balance >= _amount,
            "Insufficient contract balance."
        );
        _to.transfer(_amount);
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
