// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testMetadataAndInitialSupply() public view {
        assertEq(ourToken.name(), "OurToken");
        assertEq(ourToken.symbol(), "OTK");
        assertEq(ourToken.decimals(), 18);
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testTransfer() public {
        uint256 amount = 25 ether;
        uint256 bobBalanceBefore = ourToken.balanceOf(bob);

        vm.prank(bob);
        bool success = ourToken.transfer(alice, amount);

        assertTrue(success);
        assertEq(ourToken.balanceOf(alice), amount);
        assertEq(ourToken.balanceOf(bob), bobBalanceBefore - amount);
    }

    function testTransferEmitsTransferEvent() public {
        uint256 amount = 1 ether;

        vm.expectEmit(true, true, false, true, address(ourToken));
        emit Transfer(bob, alice, amount);

        vm.prank(bob);
        ourToken.transfer(alice, amount);
    }

    function testTransferZeroAmount() public {
        uint256 bobBalanceBefore = ourToken.balanceOf(bob);

        vm.prank(bob);
        ourToken.transfer(alice, 0);

        assertEq(ourToken.balanceOf(alice), 0);
        assertEq(ourToken.balanceOf(bob), bobBalanceBefore);
    }

    function testCannotTransferMoreThanBalance() public {
        uint256 amount = STARTING_BALANCE + 1;

        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, bob, STARTING_BALANCE, amount)
        );
        vm.prank(bob);
        ourToken.transfer(alice, amount);
    }

    function testCannotTransferToZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        vm.prank(bob);
        ourToken.transfer(address(0), 1);
    }

    function testApproveSetsAllowanceAndEmitsEvent() public {
        uint256 amount = 50 ether;

        vm.expectEmit(true, true, false, true, address(ourToken));
        emit Approval(bob, alice, amount);

        vm.prank(bob);
        bool success = ourToken.approve(alice, amount);

        assertTrue(success);
        assertEq(ourToken.allowance(bob, alice), amount);
    }

    function testApproveReplacesExistingAllowance() public {
        vm.prank(bob);
        ourToken.approve(alice, 50 ether);

        vm.prank(bob);
        ourToken.approve(alice, 20 ether);

        assertEq(ourToken.allowance(bob, alice), 20 ether);
    }

    function testCannotApproveZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        vm.prank(bob);
        ourToken.approve(address(0), 1);
    }

    function testTransferFromSpendsAllowanceAndMovesTokens() public {
        uint256 allowanceAmount = 50 ether;
        uint256 transferAmount = 15 ether;

        vm.prank(bob);
        ourToken.approve(alice, allowanceAmount);

        vm.prank(alice);
        bool success = ourToken.transferFrom(bob, alice, transferAmount);

        assertTrue(success);
        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.allowance(bob, alice), allowanceAmount - transferAmount);
    }

    function testTransferFromCanUseExactAllowance() public {
        vm.prank(bob);
        ourToken.approve(alice, 10 ether);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 10 ether);

        assertEq(ourToken.allowance(bob, alice), 0);
        assertEq(ourToken.balanceOf(alice), 10 ether);
    }

    function testInfiniteAllowanceIsNotReduced() public {
        vm.prank(bob);
        ourToken.approve(alice, type(uint256).max);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 10 ether);

        assertEq(ourToken.allowance(bob, alice), type(uint256).max);
    }

    function testCannotTransferFromWithoutAllowance() public {
        uint256 amount = 1 ether;

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, alice, 0, amount));
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, amount);
    }

    function testCannotTransferFromAboveAllowance() public {
        vm.prank(bob);
        ourToken.approve(alice, 5 ether);

        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, alice, 5 ether, 6 ether)
        );
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 6 ether);
    }

    function testCannotTransferFromAboveOwnerBalance() public {
        uint256 amount = STARTING_BALANCE + 1;
        vm.prank(bob);
        ourToken.approve(alice, amount);

        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, bob, STARTING_BALANCE, amount)
        );
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, amount);
    }

    function testTransferFromDoesNotConsumeAllowanceOnFailure() public {
        vm.prank(bob);
        ourToken.approve(alice, 5 ether);

        vm.expectRevert();
        vm.prank(alice);
        ourToken.transferFrom(bob, address(0), 1 ether);

        assertEq(ourToken.allowance(bob, alice), 5 ether);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testTotalSupplyDoesNotChangeOnTransfer() public {
        uint256 supplyBefore = ourToken.totalSupply();

        vm.prank(bob);
        ourToken.transfer(alice, 10 ether);

        assertEq(ourToken.totalSupply(), supplyBefore);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
