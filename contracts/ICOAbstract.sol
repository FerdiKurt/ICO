// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import './ICOStorage.sol';

abstract contract ICOAbstract is ICOStorage {
    // functions to be implemented
    function start(
    uint duration,
    uint price,
    uint availableTokens,
    uint allowedTokens,
    uint percentage
    ) external virtual;

    function addToWhitelist(address investor) external virtual;
    function buy(uint amount) external virtual payable;  
    function release() external virtual;
    function withdraw(address payable recipient, uint amount) external virtual payable;

    // modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only admin!');
        _;
    }
    modifier onlyInvestors() {
        require(investors[msg.sender] == true, 'Only investors!');
        _;
    }

    modifier icoNotActive() {
        require(endOfICO == 0, 'ICO should not be active!');
        _;
    }
    modifier icoActive() {
        require(
            endOfICO > 0 && endOfICO > block.timestamp && availableTokens > 0,
            'ICO is not active!'
        );
        _;
    }
    modifier icoEnded() {
        require(
            endOfICO > 0 && (block.timestamp > endOfICO || availableTokens == 0),
             'ICO still active!'
        );
        _;
    }

    modifier tokensNotReleased() {
        require(released == false, 'Tokens are already released!');
        _;
    }
    modifier tokensReleased() {
        require(released == true, 'Tokens are not released yet!');
        _;
    }
}