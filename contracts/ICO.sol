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
        uint price,
        uint _availableTokens,
        uint allowedTokens,
        uint _percentage
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

        availableTokens = _availableTokens;

        require(duration > 0, 'Invalid duration provided!');
        require(price > 0, 'Invalid price provided!');

        require(_percentage <= 50, 'Invalid percentage rate is given!');
        percentage = _percentage;
        require(
            allowedTokens > 0 && allowedTokens <= ((availableTokens * percentage) / 100), 
            'Invalid purchase limit provided!'
        );

        endOfICO = duration + block.timestamp;
        pricePerToken = price;
        purchaseLimit = allowedTokens;
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
        uint balance = _balanceOfICO();
        require(amount <= balance, 'Invalid ether input!');

        recipient.transfer(amount);
    }

    function _balanceOfICO() internal view returns(uint) {
        return address(this).balance;
    }
}
