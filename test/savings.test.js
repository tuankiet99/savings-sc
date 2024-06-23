const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Savings Contract", function () {
  let savingsContract;
  let _owner;
  let _addr1;

  beforeEach(async function () {
    const [owner, addr1] = await ethers.getSigners();
    savingsContract = await ethers.deployContract("SavingsContract", [], {
      gasLimit: 4000000,
      owner,
    });
    _owner = owner;
    _addr1 = addr1;
    await savingsContract.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await savingsContract.owner()).to.equal(_owner.address);
    });
  });

  describe("Deposits", function () {
    it("Should not allow deposits with invalid term", async function () {
      const term = 3;
      const depositAmount = ethers.parseEther("10");

      await expect(
        savingsContract.connect(_addr1).deposit(term, { value: depositAmount })
      ).to.be.revertedWith("Invalid term.");
    });

    it("Should allow deposits with valid term", async function () {
      await savingsContract
        .connect(_addr1)
        .deposit(6, { value: ethers.parseEther("10") });

      const [amount, , term] = await savingsContract.getUserSaving(
        _addr1.address,
        0
      );
      expect(amount).to.equal(ethers.parseEther("10"));
      expect(term).to.equal(6);
    });
  });

  describe("Withdrawals", function () {
    beforeEach(async function () {
      const term = 6;
      const depositAmount = ethers.parseEther("10");

      await savingsContract
        .connect(_addr1)
        .deposit(term, { value: depositAmount });
    });

    it("Should not allow withdrawal before term ends", async function () {
      await expect(
        savingsContract.connect(_addr1).withdraw(0)
      ).to.be.revertedWith("The term has not expired yet.");
    });

    it("Should not allow withdrawal with insufficient contract balance", async function () {
      const term = 6;

      await savingsContract
        .connect(_owner)
        .withdrawForAdmin(_owner.address, ethers.parseEther("5"));

      // Fast-forward time by 6 months
      await ethers.provider.send("evm_increaseTime", [
        term * 30 * 24 * 60 * 60,
      ]);
      await ethers.provider.send("evm_mine");

      await expect(
        savingsContract.connect(_addr1).withdraw(0)
      ).to.be.revertedWith("Insufficient contract balance.");
    });

    it("Should allow withdrawal after term ends", async function () {
      const term = 6;
      const expectWithdrawAmount = ethers.parseEther("10.15"); // 10 tokens (deposited) + 3% interest

      // Fast-forward time by 6 months
      await ethers.provider.send("evm_increaseTime", [
        term * 30 * 24 * 60 * 60,
      ]);
      await ethers.provider.send("evm_mine");

      await expect(() =>
        savingsContract.connect(_addr1).withdraw(0)
      ).to.changeEtherBalance(_addr1, expectWithdrawAmount);
    });
  });
});
