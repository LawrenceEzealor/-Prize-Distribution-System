// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract Game is VRFConsumerBase, Ownable {

    address public owner;
    uint public fee;
    bytes32 public keyHash;
    bool public gameActivated;
    uint8 public maxParticipant;
    uint256 entryPayment;
    uint256 public gameId;
    

    //this arrays houses the lists of the participants
    //payable is for  addresses that can receive any form of payment
    address payable[] public participants;

     constructor(address vrfCoordinator, address linkToken,
    bytes32 vrfKeyHash, uint256 vrfFee)
    VRFConsumerBase(vrfCoordinator, linkToken) {
        keyHash = vrfKeyHash;
        fee = vrfFee;
        gameActivated = false;
    }


    function beginGame(uint8 _maxParticipant, uint256 _entryPayment) public onlyOwner {
        require(!gameActivated, "A Game is in progress");
        // empty the participants array
        delete participants;
        // set the max participant for this game
        maxParticipant = _maxParticipant;
        // set the game activation to true
        gameActivated = true;
        // setup the entryPayment for the game
        entryPayment = _entryPayment;
        gameId += 1;
        emit GameStarted(gameId, maxParticipant, entryPayment);
    }

    function participateInGame() public payable {
        // Check if a game is already in progress
        require(gameActivated, "A Game has not started yet");
        // Check if the value sent by the participant matches the entryPayment
        require(msg.value == entryPayment, "Value sent is not equal to entryPayment");
        // Check if there is still some space left in the game to add another participant
        require(participant.length < maxParticipant, "participants limit reached");
        // add the sender to the participants list
        participants.push(msg.sender);
        emit PlayerJoined(gameId, msg.sender);
        // If the list is full start the winner selection process
        if(participants.length == maxParticipants) {
            selectRandomWinner();
        }
    }

       function resolveRandomness(bytes32 requestId, uint256 randomness) internal virtual override  {
        // winnerIndex should be in the length from 0 to participants.length-1
        // to achieve this we mod it with the participant.length value
        uint256 winnerIndex = randomness % participants.length;
        // get the address of the winner from the participants array
        address winner = participants[winnerIndex];
        // send the ether in the contract to the winner
        (bool sent,) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        // Emit that the game has ended
        emit GameEnded(gameId, winner,requestId);
        // set the gameStarted variable to false
        gameActivated = false;
    }

      function selectRandomWinner() private returns (bytes32 requestId) {
        // LINK is an internal interface for Link token found within the VRFConsumerBase
        // Here we use the balanceOF method from that interface to make sure that our
        // contract has enough link so that we can request the VRFCoordinator for randomness
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        // Make a request to the VRF coordinator.
        // requestRandomness is a function within the VRFConsumerBase
        // it starts the process of randomness generation
        return requestRandomness(keyHash, fee);
    }

     // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}