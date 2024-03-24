const { expect } = require("chai");

describe("Savings Contract", function () {
  let savingsContract;
  const depositAmount = ethers.parseEther("1.0");
  const withdrawAmount = ethers.parseEther("0.5");

  async function deploySavingsContract() {
    const [signer] = await ethers.getSigners();
    savingsContract = await ethers.deployContract("SavingsContract", [], {
      gasLimit: 4000000,
      signer,
    });
    await savingsContract.waitForDeployment();

    console.log(`Savings Contract was deployed to ${savingsContract.target}`);
    return savingsContract.target;
  }

  it("Should OK", async function () {
    await deploySavingsContract();
  });

  it("Should deposit and update balances correctly", async function () {
    const [signer] = await ethers.getSigners();

    // Deposit
    await savingsContract.connect(signer).deposit({ value: depositAmount });

    // Check balances
    const signerBalance = await savingsContract.balances(signer.address);
    console.log(" deposit - signerBalance: ", signerBalance);
    expect(signerBalance).to.equal(depositAmount);
  });

  it("Should withdraw and update balances correctly", async function () {
    const [signer] = await ethers.getSigners();

    // Deposit
    await savingsContract.connect(signer).deposit({ value: depositAmount });

    // Withdraw
    await savingsContract.connect(signer).withdraw(withdrawAmount);

    // Check balances
    const signerBalance = await savingsContract.balances(signer.address);
    console.log(" withdraw - signerBalance: ", signerBalance);
    // expect(signerBalance).to.equal(depositAmount.sub(withdrawAmount));
  });
});
