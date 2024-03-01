import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("PrizeDistribution", function () {
  // Fixture to deploy the PrizeDistribution contract and an ERC20 token mock
  async function deployPrizeDistributionFixture() {
    const [owner, participant1, participant2] = await ethers.getSigners();

    // Deploy an ERC20 Token Mock
    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy(
      "TestToken",
      "TT",
      "18",
      ethers.parseEther("1000000")
    );

    // Deploy the PrizeDistribution contract
    const PrizeDistribution = await ethers.getContractFactory(
      "PrizeDistribution"
    );
    const prizeDistribution = await PrizeDistribution.deploy(
      /* VRF Coordinator */ owner.address,
      /* LINK Token */ token.target,
      ethers.encodeBytes32String("keyHash"),
      //  /* keyHash */ ethers.formatBytes32String("keyHash"),
      /* fee */ ethers.parseEther("0.1"),
      /* rewardsTokenAddress */ token.target,
      /* prizePool */ ethers.parseEther("1000"),
      /* numberOfWinners */ 2
    );

    // Transfer tokens to the PrizeDistribution contract for rewards
    await token.transfer(prizeDistribution.target, ethers.parseEther("1000"));

    return { prizeDistribution, token, owner, participant1, participant2 };
  }

  it("Should register participants and add entries", async function () {
    const { prizeDistribution, participant1, participant2 } = await loadFixture(
      deployPrizeDistributionFixture
    );

    // Register participants
    await expect(prizeDistribution.connect(participant1).registerParticipant())
      .to.emit(prizeDistribution, "ParticipantRegistered")
      .withArgs(participant1.address);

    await expect(prizeDistribution.connect(participant2).registerParticipant())
      .to.emit(prizeDistribution, "ParticipantRegistered")
      .withArgs(participant2.address);

    // Add entries for participants
    await expect(
      prizeDistribution
        .connect(participant1)
        .addEntries(participant1.address, 5)
    )
      .to.emit(prizeDistribution, "EntriesAdded")
      .withArgs(participant1.address, 5);

    await expect(
      prizeDistribution
        .connect(participant2)
        .addEntries(participant2.address, 10)
    )
      .to.emit(prizeDistribution, "EntriesAdded")
      .withArgs(participant2.address, 10);
  });

  it("Should trigger prize distribution", async function () {
    const { prizeDistribution, owner } = await loadFixture(
      deployPrizeDistributionFixture
    );

    // Trigger prize distribution
    await expect(
      prizeDistribution.connect(owner).triggerPrizeDistribution()
    ).to.emit(prizeDistribution, "PrizeDistributionTriggered");
  });

});
