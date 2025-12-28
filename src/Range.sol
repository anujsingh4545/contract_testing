// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract Range {
    int public number1;
    uint public number2;

    int private initialNumber1;
    uint private initialNumber2;

    address public owner;

    constructor(int _number1, uint _number2) {
        number1 = _number1;
        number2 = _number2;

        initialNumber1 = _number1;
        initialNumber2 = _number2;

        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function increment() public onlyOwner {
        number1 += 1;
        number2 += 1;
    }

    function decrement() public onlyOwner {
        require(number2 > 0, "Can't decrement anymore");

        number1 -= 1;
        number2 -= 1;
    }

    function getBoth() public view onlyOwner returns (int, uint) {
        return (number1, number2);
    }

    function reset() public onlyOwner {
        number1 = initialNumber1;
        number2 = initialNumber2;
    }
}
