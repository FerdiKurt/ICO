// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

import './ICOStructs.sol';

contract ICOStorage is ICOStructs {
    uint public endOfICO;
    uint public pricePerUnit;
    uint public availableTokens;
    uint public minPurchase;
    uint public maxPurchase;
    bool public released;

    address public admin;
    address public token;

    Sale[] public sales;
    
    mapping(address => bool) public investors;
}