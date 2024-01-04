// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {EthPriceConverter} from "./EthPriceConverter.sol";

error FundMe__NotOwner();
error FundMe__NotEnoughUSD();

contract FundMe {

    using EthPriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address payable private immutable i_owner;
    address[] private s_funders;
    mapping(address funder => uint256 amount) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = payable(msg.sender);
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier onlyOwner() {
        if(msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    modifier minimumAmount() {
        if(!(msg.value.convertEthToUsd(s_priceFeed) >= MINIMUM_USD)){
            revert FundMe__NotEnoughUSD();
        }
        _;
    }

    function fund() public payable minimumAmount {
        // require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        // if(!(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD)){
        //     revert FundMe__NotEnoughUSD();
        // }
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for(uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        if(!success){
            revert FundMe__NotOwner();
        }
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        if(!success){
            revert FundMe__NotOwner();
        }
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }

    function getFunder(uint256 funderIndex) external view returns(address) {
        return s_funders[funderIndex];
    }

    function getAddressToAmountFunded(address funderAddress) external view returns(uint256) {
        return s_addressToAmountFunded[funderAddress];
    }

}