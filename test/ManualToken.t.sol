// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ManualToken} from "../src/ManualToken.sol";
import {DeployManualToken} from "../script/DeployManualToken.s.sol";

contract ManualTokenTest is Test {
    ManualToken private token;

    address private owner;
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private spender = makeAddr("spender");

    uint256 private constant INITIAL_SUPPLY = 100000000 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    function setUp() public {
        owner = makeAddr("owner");
        vm.prank(owner);
        token = new ManualToken();
    }

    function testMetadataOwnerAndInitialSupply() public view {
        assertEq(token.name(), "ManualToken");
        assertEq(token.symbol(), "MTK");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.balanceOf(alice), 0);
    }

    function testDeployManualTokenRunDeploysTokenWithInitialSupply() public {
        DeployManualToken deployer = new DeployManualToken();

        ManualToken deployedToken = deployer.run();

        assertTrue(address(deployedToken) != address(0));
        assertEq(deployedToken.name(), "ManualToken");
        assertEq(deployedToken.symbol(), "MTK");
        assertEq(deployedToken.decimals(), 18);
        assertEq(deployedToken.totalSupply(), INITIAL_SUPPLY);
        assertTrue(deployedToken.owner() != address(0));
        assertEq(deployedToken.balanceOf(deployedToken.owner()), INITIAL_SUPPLY);
        assertEq(address(deployer.manualToken()), address(deployedToken));
    }

    function testConstructorEmitsInitialMintTransfer() public {
        address deployer = makeAddr("deployer");
        // The new instance has a different address, so match the log from any emitter.
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), deployer, INITIAL_SUPPLY);
        vm.prank(deployer);
        new ManualToken();
    }

    function testTransferMovesTokensAndEmitsEvent() public {
        uint256 amount = 25 ether;
        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(owner, alice, amount);

        vm.prank(owner);
        assertTrue(token.transfer(alice, amount));
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testTransferZeroAmount() public {
        vm.prank(owner);
        assertTrue(token.transfer(alice, 0));
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.balanceOf(alice), 0);
    }

    function testTransferRevertsOnInsufficientBalance() public {
        vm.expectRevert(ManualToken.ManualToken__InsufficientBalance.selector);
        vm.prank(alice);
        token.transfer(bob, 1);
    }

    function testTransferRevertsToZeroAddress() public {
        vm.expectRevert(ManualToken.ManualToken__InvalidAddress.selector);
        vm.prank(owner);
        token.transfer(address(0), 1);
    }

    function testApproveSetsAndEmitsAllowance() public {
        uint256 amount = 42 ether;
        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(owner, spender, amount);

        vm.prank(owner);
        assertTrue(token.approve(spender, amount));
        assertEq(token.allowance(owner, spender), amount);
    }

    function testApproveReplacesAllowanceAndAllowsZero() public {
        vm.startPrank(owner);
        token.approve(spender, 10 ether);
        token.approve(spender, 3 ether);
        token.approve(spender, 0);
        vm.stopPrank();

        assertEq(token.allowance(owner, spender), 0);
    }

    function testTransferFromMovesTokensAndConsumesAllowance() public {
        uint256 approved = 30 ether;
        uint256 amount = 12 ether;
        vm.prank(owner);
        token.approve(spender, approved);

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(owner, alice, amount);
        vm.prank(spender);
        assertTrue(token.transferFrom(owner, alice, amount));

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.allowance(owner, spender), approved - amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testTransferFromCanSpendExactAllowance() public {
        vm.prank(owner);
        token.approve(spender, 1 ether);
        vm.prank(spender);
        token.transferFrom(owner, bob, 1 ether);
        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.balanceOf(bob), 1 ether);
    }

    function testTransferFromRevertsWithoutEnoughAllowance() public {
        vm.prank(owner);
        token.approve(spender, 1 ether);
        vm.expectRevert(ManualToken.ManualToken__InsufficientAllowance.selector);
        vm.prank(spender);
        token.transferFrom(owner, alice, 2 ether);
        assertEq(token.allowance(owner, spender), 1 ether);
    }

    function testTransferFromRevertsWithoutEnoughBalance() public {
        vm.prank(alice);
        token.approve(spender, 1 ether);
        vm.expectRevert(ManualToken.ManualToken__InsufficientBalance.selector);
        vm.prank(spender);
        token.transferFrom(alice, bob, 1 ether);
        assertEq(token.allowance(alice, spender), 1 ether);
    }

    function testTransferFromRevertsToZeroAddressAndRollsBackAllowance() public {
        vm.prank(owner);
        token.approve(spender, 2 ether);
        vm.expectRevert(ManualToken.ManualToken__InvalidAddress.selector);
        vm.prank(spender);
        token.transferFrom(owner, address(0), 1 ether);
        assertEq(token.allowance(owner, spender), 2 ether);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function testBurnReducesBalanceAndSupplyAndEmitsEvent() public {
        uint256 amount = 5 ether;
        vm.expectEmit(true, false, false, true, address(token));
        emit Burn(owner, amount);
        vm.prank(owner);
        assertTrue(token.burn(amount));
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - amount);
    }

    function testBurnZeroAmount() public {
        vm.prank(owner);
        assertTrue(token.burn(0));
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testBurnRevertsOnInsufficientBalance() public {
        vm.expectRevert(ManualToken.ManualToken__InsufficientBalance.selector);
        vm.prank(alice);
        token.burn(1);
    }

    function testBurnFromConsumesAllowanceAndReducesSupply() public {
        uint256 approved = 8 ether;
        uint256 amount = 3 ether;
        vm.prank(owner);
        token.approve(spender, approved);

        vm.expectEmit(true, false, false, true, address(token));
        emit Burn(owner, amount);
        vm.prank(spender);
        assertTrue(token.burnFrom(owner, amount));

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - amount);
        assertEq(token.allowance(owner, spender), approved - amount);
    }

    function testBurnFromRevertsForInsufficientBalance() public {
        vm.prank(alice);
        token.approve(spender, 1 ether);
        vm.expectRevert(ManualToken.ManualToken__InsufficientBalance.selector);
        vm.prank(spender);
        token.burnFrom(alice, 1 ether);
        assertEq(token.allowance(alice, spender), 1 ether);
    }

    function testBurnFromRevertsForInsufficientAllowance() public {
        vm.expectRevert(ManualToken.ManualToken__InsufficientAllowance.selector);
        vm.prank(spender);
        token.burnFrom(owner, 1 ether);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function testMintIncreasesSupplyAndBalanceAndEmitsTransfer() public {
        uint256 amount = 7 ether;
        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(address(0), alice, amount);
        vm.prank(owner);
        assertTrue(token.mint(alice, amount));
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + amount);
    }

    function testMintZeroAmount() public {
        vm.prank(owner);
        assertTrue(token.mint(alice, 0));
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testMintRevertsForNonOwner() public {
        vm.expectRevert(ManualToken.ManualToken__NotOwner.selector);
        vm.prank(alice);
        token.mint(alice, 1 ether);
    }

    function testMintRevertsToZeroAddress() public {
        vm.expectRevert(ManualToken.ManualToken__InvalidAddress.selector);
        vm.prank(owner);
        token.mint(address(0), 1 ether);
    }
}
