// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Wallet {
    address public owner;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function deposit() external payable {
        require(msg.value > 0, "No ETH sent");
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds");

        (bool success, ) = owner.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdraw(owner, amount);
    }
}
