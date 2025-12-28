// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.2 <0.9.0;

import "forge-std/Test.sol";
import "../src/Range.sol";

contract TestRange is Test{
    Range range;

    address owner  = address(1);
    address user = address(2);


    function setUp() public{
        vm.prank(owner);
        range = new Range(5,10);
    }


    function testIncreament() public{
        vm.startPrank(owner);
        range.increment();
        (int n1, uint n2) = range.getBoth();
        assertEq(n1, 6);
        assertEq(n2, 11);
        vm.stopPrank();
    }

    function testFuzzIncreament(uint8 times) public {
        vm.assume(times < 50);
        vm.startPrank(owner);
        for(uint i= 0 ; i <times ; i++){
            range.increment();
        }
        (int n1, uint n2) = range.getBoth();
        vm.stopPrank();
        assertEq(n1, 5 + int256(uint256(times)));
        assertEq(n2, 10 + uint256(times));
    }

    function testIncreamentRevertsIfNotOwner() public{
        vm.startPrank(user);
        vm.expectRevert("Not owner");
        range.increment();
        vm.stopPrank();
    }

    function testDecreament() public{
        vm.startPrank(owner);
        range.decrement();
        (int n1, uint n2) = range.getBoth();
        assertEq(n1, 4);
        assertEq(n2, 9);
        vm.stopPrank();
    }

    function testDecreamentRevertsAtZero() public{
        vm.startPrank(owner);
        range = new Range(5,0);
        vm.expectRevert("Can't decrement anymore");
        range.decrement();
        vm.stopPrank();
    }

    function testReset () public{
        vm.startPrank(owner);
        range.increment();
        range.reset();
        (int n1, uint n2) = range.getBoth();
        assertEq(n1, 5);
        assertEq(n2, 10);
        vm.stopPrank();
    }
}