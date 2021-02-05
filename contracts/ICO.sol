// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

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
        uint _duration,
        uint _price,
        uint _availableTokens,
        uint _allowedTokens,
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

        require(_duration > 0, 'Invalid duration provided!');
        require(_price > 0, 'Invalid price provided!');

        require(_percentage <= 50, 'Invalid percentage rate is given!');
        percentage = _percentage;
        require(
            _allowedTokens > 0 && _allowedTokens <= ((availableTokens * percentage) / 100), 
            'Invalid purchase limit provided!'
        );

        endOfICO = _duration + block.timestamp;
        pricePerToken = _price;
        purchaseLimit = _allowedTokens;
    }

    function addToWhitelist(address _investor) external onlyAdmin() override {
        investors[_investor] = true;
    }

    function buy(uint _tokensAmount) external onlyInvestors() icoActive() payable override {
        require(_tokensAmount <= availableTokens, 'Not enough tokens for sale!');
        require(_tokensAmount <= purchaseLimit, 'Invalid token amount!');

        uint requiredPrice = _tokensAmount * pricePerToken;
        require(msg.value >= requiredPrice, 'Not enough ether provided!');

        if (msg.value > requiredPrice) {
            payable(msg.sender).transfer(msg.value - requiredPrice);
        }

        availableTokens -= _tokensAmount;
        sales.push(Sale(msg.sender, _tokensAmount));
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
        address payable _recipient,
        uint _amount
    )
        external
        onlyAdmin()
        icoEnded()
        tokensReleased()
        payable
        override
    {
        uint balance = _balanceOfICO();
        require(_amount <= balance, 'Invalid ether input!');

        _recipient.transfer(_amount);
    }

    function _balanceOfICO() internal view returns(uint) {
        return address(this).balance;
    }
}
