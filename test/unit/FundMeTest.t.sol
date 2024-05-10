// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
	FundMe fundMe;
	address user = makeAddr("user");
	uint256 constant SEND_VALUE = 0.1 ether;
	uint256 constant STARTING_BALANCE = 10 ether;
	uint256 constant GAS_PRICE = 1;

	function setUp() external {
		DeployFundMe deployFundMe = new DeployFundMe();
		fundMe = deployFundMe.run();
		vm.deal(user, STARTING_BALANCE);
	}
	function testMinimumDollar() public view {
		assertEq(fundMe.MINIMUM_USD(), 5e18);
	}
	function testOwnerIsMsgSender() public view {
		assertEq(fundMe.getOwner(), msg.sender);
	}
	function testPriceFeedVersion() public view {
		uint256 version = fundMe.getVersion();
		assertEq(version, 4);
	}
	function testFundFail() public {
		vm.expectRevert();
		fundMe.fund();
	}
	function testFundUpdatesFundedDataStructure() public {
		vm.prank(user);
		fundMe.fund{value: SEND_VALUE}();

		uint256 amountFunded = fundMe.getAddressToAmountFunded(user);
		assertEq(amountFunded, SEND_VALUE);
	}
	modifier funded() {
		vm.prank(user);
		fundMe.fund{value: SEND_VALUE}();
		_;
	}
	function testAddsFunderToArray() public funded {
		address funder = fundMe.getFunder(0);
		assertEq(funder, user);
	}
	function testOnlyOwnerCanWithdraw() public funded {
		vm.expectRevert();
		vm.prank(user);
		fundMe.withdraw();
	}
	function testWithdrawWithSingleFunder() public funded {
		uint256 startingOwnerBalance = fundMe.getOwner().balance;
		uint256 startingFundMeBalance = address(fundMe).balance;

		vm.prank(fundMe.getOwner());
		fundMe.withdraw();

		uint256 endingOwnerBalance = fundMe.getOwner().balance;
		uint256 endingFundMeBalance = address(fundMe).balance;
		assertEq(endingFundMeBalance, 0);
		assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
	}
	function testWithdrawWithMultipleFunders() public funded {
		uint160 numberOfFunders = 10;
		uint160 startingFunderIndex = 1;
		for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
			hoax(address(i), SEND_VALUE);
			fundMe.fund{value: SEND_VALUE}();
		}
		uint256 startingOwnerBalance = fundMe.getOwner().balance;
		uint256 startingFundMeBalance = address(fundMe).balance;

		// uint256 gasStart = gasleft();
		// vm.txGasPrice(GAS_PRICE);
		vm.prank(fundMe.getOwner());
		fundMe.withdraw();
		// uint256 gasEnd = gasleft();
		// uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
		// console.log(gasUsed);

		assert(address(fundMe).balance == 0);
		assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
	}
	function testWithdrawWithMultipleFundersCheaper() public funded {
		uint160 numberOfFunders = 10;
		uint160 startingFunderIndex = 1;
		for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
			hoax(address(i), SEND_VALUE);
			fundMe.fund{value: SEND_VALUE}();
		}
		uint256 startingOwnerBalance = fundMe.getOwner().balance;
		uint256 startingFundMeBalance = address(fundMe).balance;

		// uint256 gasStart = gasleft();
		// vm.txGasPrice(GAS_PRICE);
		vm.prank(fundMe.getOwner());
		fundMe.cheaperWithdraw();
		// uint256 gasEnd = gasleft();
		// uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
		// console.log(gasUsed);

		assert(address(fundMe).balance == 0);
		assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
	}
}