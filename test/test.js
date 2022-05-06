const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Blockchain_edge", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Edge = await ethers.getContractFactory("Blockchain_edge");
    const edge = await Edge.deploy();
    await edge.deployed();

    await edge.setAvailable('0.1',{ value: ethers.utils.parseEther("1") })
    expect(await edge.bid()).to.equal('0.1');

    // wait until the transaction is mined
  
  });
});


