// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    FundMe fundMe;
    uint256 constant SEND_VALUE = 1e17;
    uint256 constant STARTING_BALANCE = 10e18;
    address USER = makeAddr("user");
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEth() public {
        vm.expectRevert();
        fundMe.fund();
    }


    function testFundUpdatesFundedDataStructure() public {
        // FundMeTest is address(this)
        // fundMe.fund{value: 10e18}();
        // uint256 amountFunded = fundMe.getAddressToAmountFunded(address(this));
        // assertEq(amountFunded, 10e18);

        // Using a fake user from the foundry cheatcode
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE};
        _;
    }
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 ownerStartBalance = fundMe.getOwner().balance;
        uint256 fundMeStartBalance = address(fundMe).balance;

        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        uint256 ownerEndBalance = fundMe.getOwner().balance;
        uint256 fundMeEndBalance = address(fundMe).balance;
        assertEq(ownerStartBalance + fundMeStartBalance, ownerEndBalance);
        assertEq(fundMeEndBalance, 0);
    }

    function testWithdrawFromMultipleFunders() public {
        // In order to generate addresses with numbers the numbers must be uint160
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE); //hoax creates an address and give it money at same time
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 ownerStartBalance = fundMe.getOwner().balance;
        uint256 fundMeStartBalance = address(fundMe).balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 ownerEndBalance = fundMe.getOwner().balance;
        uint256 fundMeEndBalance = address(fundMe).balance;
        assertEq(ownerStartBalance + fundMeStartBalance, ownerEndBalance);
        assertEq(fundMeEndBalance, 0);
    }

    function testWithdrawFromMultipleFundersCheaper() public {
        // In order to generate addresses with numbers the numbers must be uint160
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE); //hoax creates an address and give it money at same time
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 ownerStartBalance = fundMe.getOwner().balance;
        uint256 fundMeStartBalance = address(fundMe).balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        uint256 ownerEndBalance = fundMe.getOwner().balance;
        uint256 fundMeEndBalance = address(fundMe).balance;
        assertEq(ownerStartBalance + fundMeStartBalance, ownerEndBalance);
        assertEq(fundMeEndBalance, 0);
    }
}