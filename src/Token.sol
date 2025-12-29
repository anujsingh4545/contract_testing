// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Token{

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address=> uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _iniitalSupply ){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balanceOf[msg.sender] = _iniitalSupply; // only initial minting allowed
        totalSupply = _iniitalSupply;
    }

    // we don't check for amount>0, as some tokens allow it.
    function transfer(address to, uint256 amount) external returns(bool){
        require(to != address(0), "Zero Address");
        require(balanceOf[msg.sender] >= amount , "Insufficient balance!");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // we don't check current owner has even this much money or not, as it's a promise, in future maybe owner gonna get some money.
    function approve(address spender, uint256 amount) external returns(bool) {
        require(spender != address(0), "Zero Address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns(bool){
        require(to != address(0), "Zero address");
        require(amount> 0, "Invalid amount!"); 
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        allowance[from][msg.sender] -= amount;
        balanceOf[from]-= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);  
        return true;
    }

}

