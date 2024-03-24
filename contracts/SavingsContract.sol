// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SavingsContract {
    address payable public owner;
    mapping(address => uint) public balances;
    mapping(address => uint) public depositTimes;
    // uint itemFee = 0.001 ether;

    uint public interestRate = 3;

    constructor() payable {
        owner = payable(msg.sender);
        balances[address(this)] += msg.value;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        depositTimes[msg.sender] = block.timestamp;
    }

    function withdraw(uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient Ether balance.");

        uint interest = calculateInterest(msg.sender, amount);
        uint totalAmount = amount + interest;

        require(
            balances[address(this)] >= interest,
            "Insufficient contract balance for interest."
        );

        balances[msg.sender] -= amount;
        balances[address(this)] -= interest;
        payable(msg.sender).transfer(totalAmount);
    }

    function withdrawForAdmin(address payable to, uint amount) external {
        require(isOwner(), "Only the owner can withdraw for admin.");
        require(
            balances[address(this)] >= amount,
            "Insufficient contract balance."
        );

        payable(to).transfer(amount);
        balances[address(this)] -= amount;
    }

    function calculateInterest(
        address account,
        uint amount
    ) internal view returns (uint) {
        uint elapsedTime = block.timestamp - depositTimes[account];
        uint annualInterest = (amount * interestRate) / 100;
        uint interest = (elapsedTime * annualInterest) / 365 days;
        return interest;
    }
}
