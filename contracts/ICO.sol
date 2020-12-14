// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

import { ERC20Token }  from './ERC20Token.sol';
import './ICOAbstract.sol';

contract ICO is ICOAbstract { 
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _initialSupply
    ) {
        token = address(new ERC20Token(
            _name,
            _symbol,
            _decimals,
            _initialSupply
        ));

        admin = msg.sender;
    }

    function start(
        uint duration,
        uint _price,
        uint _availableTokens,
        uint _min,
        uint _max
    )
        external
        onlyAdmin()
        icoNotActive()
        override
    {
        uint totalSupply = ERC20Token(token).totalSupply();
        require(
            _availableTokens > 0 && _availableTokens <= totalSupply,
            'Invalid amount provided!'
        );

        require(duration > 0, 'Invalid duration provided!');
        require(_price > 0, 'Invalid price proided!');
        require(_min > 0, 'Min must be greater than 0!');
        require(_max > 0 && _max < _availableTokens, 'Invalid max purchase provided!');

        endOfICO = duration + block.timestamp;
        pricePerUnit = _price;
        availableTokens = _availableTokens;
        minPurchase = _min;
        maxPurchase = _max;
    }

    function addToWhitelist(address investor) external onlyAdmin() override {
        investors[investor] = true;
    }

    function buy(uint tokensAmount) external onlyInvestors() icoActive() payable override {
        require(tokensAmount <= availableTokens, 'Not enough tokens for sale!');
        require(tokensAmount <= purchaseLimit, 'Invalid token amount!');

        uint requiredPrice = tokensAmount * pricePerToken;
        require(msg.value >= requiredPrice, 'Not enough ether provided!');

        if (msg.value > requiredPrice) {
            msg.sender.transfer(msg.value - requiredPrice);
        }

        availableTokens -= tokensAmount;
        sales.push(Sale(msg.sender, tokensAmount));
    }

    function release()
        onlyAdmin()
        external
        icoEnded()
        tokensNotReleased()
        override
    {
        ERC20Token erc20Token = ERC20Token(token);

        for (uint i = 0; i < sales.length; i++) {
            Sale storage sale = sales[i];
            erc20Token.transfer(sale.investor, sale.tokensAmount);
        }

        released = true;
    }

    function withdraw
    (
        address payable recipient,
        uint amount
    )
        external
        onlyAdmin()
        icoEnded()
        tokensReleased()
        payable
        override
    {
        recipient.transfer(amount);
    }
}
