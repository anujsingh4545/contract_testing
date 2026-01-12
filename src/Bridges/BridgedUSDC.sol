// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract BridgedUSDC is ERC20 {
    address public immutable bridgeB;

    constructor(address _bridgeB) ERC20("Bridged USD Coin", "BUSDC") {
        bridgeB = _bridgeB;
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    modifier onlyBridgeB() {
        require(msg.sender == bridgeB, "Not BridgeB");
        _;
    }

    function mint(address to, uint256 amount) external onlyBridgeB {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyBridgeB {
        _burn(from, amount);
    }
}
