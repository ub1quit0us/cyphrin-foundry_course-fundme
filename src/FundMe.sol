// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.30;

// 2. Imports
import "forge-std/console.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// 3. Interfaces, Libraries, contracts
error NotOwner();

contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;
    //  Variables
    uint256 public constant MIN_USD = 1e18;
    address[] private s_funders;
    address private immutable i_owner;
    mapping(address funder => uint256 amountFounded)
        private s_addressToAmountFunded;
    AggregatorV3Interface public s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not the owner.");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // Functions
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
        require(
            address(s_priceFeed) != address(0),
            "Invalid price feed address"
        );
    }

    // Funds the contract based on ETH/USD price.
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "Minimum threshold not met."
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;

        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // View / Pure functions - getter functions

    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
