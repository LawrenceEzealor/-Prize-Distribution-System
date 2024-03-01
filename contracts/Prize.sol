// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Prize is VRFConsumerBase {
    IERC20 public rewardsToken;
    bytes32 internal keyHash;
    uint256 internal fee;

    // Struct to hold participant data
    struct Participant {
        uint256 entries; // Number of entries in the prize draw
        bool isRegistered;
    }

    // State variables
    mapping(address => Participant) public participants;
    address[] public participantsList;
    uint256 public totalEntries;
    uint256 public prizePool;
    uint256 public numberOfWinners;
    bool public prizeDistributionStarted = false;

    // Events
    event ParticipantRegistered(address participant);
    event EntriesAdded(address participant, uint256 entries);
    event PrizeDistributionTriggered(uint256 randomSeed);
    event WinnerSelected(address winner, uint256 prizeAmount);

    // Constructor
    constructor(
        address _vrfCoordinator, 
        address _linkToken, 
        bytes32 _keyHash, 
        uint256 _fee, 
        address _rewardsTokenAddress,
        uint256 _prizePool,
        uint256 _numberOfWinners
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;
        rewardsToken = IERC20(_rewardsTokenAddress);
        prizePool = _prizePool;
        numberOfWinners = _numberOfWinners;
    }

    // Function to register a participant
    function registerParticipant() external {
        require(!participants[msg.sender].isRegistered, "Already registered");
        participants[msg.sender].isRegistered = true;
        participantsList.push(msg.sender);
        emit ParticipantRegistered(msg.sender);
    }

    // Function to add entries for a participant
    function addEntries(address participant, uint256 entries) external {
        require(participants[participant].isRegistered, "you are not registered");
        participants[participant].entries += entries;
        totalEntries += entries;
        emit EntriesAdded(participant, entries);
    }

    // Function to trigger prize dallocation
    function triggerPrizeAllocation() external {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        require(!prizeDistributionStarted, "Prize allocation already started");
        prizeDistributionStarted = true;
        requestRandomness(keyHash, fee);
    }

    // Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        distributePrizes(randomness);
    }

    // Function to distribute prizes
    function distributePrizes(uint256 randomSeed) private {
        uint256[] memory winners = selectWinners(randomSeed);
        uint256 prizeAmountPerWinner = prizePool / winners.length;
        for (uint256 i = 0; i < winners.length; i++) {
            rewardsToken.transfer(participantsList[winners[i]], prizeAmountPerWinner);
            emit WinnerSelected(participantsList[winners[i]], prizeAmountPerWinner);
        }
    }

    // Function to select winners
    function selectWinners(uint256 randomSeed) private view returns (uint256[] memory) {
        uint256[] memory winners = new uint256[](numberOfWinners);
        for (uint256 i = 0; i < numberOfWinners; i++) {
            uint256 winnerIndex = (uint256(keccak256(abi.encode(randomSeed, i))) % totalEntries) + 1;
            uint256 counter = 0;
            for (uint256 j = 0; j < participantsList.length; j++) {
                counter += participants[participantsList[j]].entries;
                if (counter >= winnerIndex) {
                    winners[i] = j;
                    break;
                }
            }
        }
        return winners;
    }
}