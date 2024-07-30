// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("Nic"); // Creates a fake user address for testing
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000
    uint256 constant STARTING_BAL = 10 ether; 
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BAL); // Giving USER fake money to interact with contract
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender); //check if i_owner in fundMe contract is us
    }

    // What can we do to work with addresses outside our system?
    // 1. Unit
    //  - Testing a specific part of our contract
    // 2. Integration
    //  - Testing how our code works with other parts fo our code
    // 3. Forked
    //  - Testing our code on a simulated real environment
    // 4. Staging
    //  - Test our code in a real environment that is not prod

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //hey, the next line should revert!
        fundMe.fund();
    }

    function testFundUpdates() public {
        vm.prank(USER); //The next Tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testWithdrawOnlyOwner() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange 
        uint256 startingOwnerBal = fundMe.getOwner().balance;
        uint256 startingFundMeBal = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner()); // 200 gas
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBal = fundMe.getOwner().balance;
        uint256 endingFundsBal = address(fundMe).balance;
        assertEq(endingFundsBal, 0);
        assertEq(startingFundMeBal + startingOwnerBal, endingOwnerBal);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vn.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), STARTING_BAL);
            fundMe.fund{value: SEND_VALUE}();
            // Fund the fundMe
        }

        uint256 startingFundMeBal = address(fundMe).balance;
        uint256 startingOwnerBal = fundMe.getOwner().balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBal + startingOwnerBal == fundMe.getOwner().balance);

    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.prank new address
            // vm.deal new address
            // address()
            hoax(address(i), STARTING_BAL);
            fundMe.fund{value: SEND_VALUE}();
            // Fund the fundMe
        }

        uint256 startingFundMeBal = address(fundMe).balance;
        uint256 startingOwnerBal = fundMe.getOwner().balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBal + startingOwnerBal == fundMe.getOwner().balance);

    }

}


    