// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

import './ICOStructs.sol';

contract ICOStorage is ICOStructs {
    uint public endOfICO;
    uint public pricePerToken;
    uint public availableTokens;
    uint public purchaseLimit;
    uint public percentage;
    bool public released;

    address public admin;
    address public token;

    Sale[] public sales;
    
    mapping(address => bool) public investors;
}