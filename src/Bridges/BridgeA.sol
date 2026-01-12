// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./MockUSDC.sol";

contract BridgeA {

    MockUSDC public immutable mockUSDC;

    mapping(bytes32 => bool) public processedMessages;

    event Locked( address indexed user, uint256 amount, bytes32 indexed messageId);

    event Unlocked(address indexed user, uint256 amount,bytes32 indexed messageId);

    constructor(address _mockUSDC) {
        mockUSDC = MockUSDC(_mockUSDC);
    }

    function lock(uint256 amount) external returns (bytes32 messageId) {
        require(amount > 0, "Amount = 0");
        mockUSDC.transferFrom(msg.sender, address(this), amount);

        messageId = keccak256( abi.encodePacked(msg.sender, amount, block.number, address(this)));

        emit Locked(msg.sender, amount, messageId);
    }

    function unlock(address user, uint256 amount, bytes32 messageId) external {
        require(amount > 0, "Amount = 0");
        require(!processedMessages[messageId], "Message already processed");

        processedMessages[messageId] = true;

        mockUSDC.transfer(user, amount);

        emit Unlocked(user, amount, messageId);
    }
}
