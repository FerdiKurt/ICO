// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

import './IERC20Token.sol';

contract ERC20Token is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;

    modifier notAllowed(address to) {
        require(to != address(0x00), 'Zero Address Not Allowed!');
        _;
    }

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = _initialSupply;
        balances[msg.sender] = _totalSupply;   
    }
        
    function transfer(
        address to, 
        uint value
    ) 
        external
        notAllowed(to) 
        override
        returns(bool) 
    {
        require(balances[msg.sender] >= value, 'token balance too low');

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(
        address from, 
        address to, 
        uint value
    ) 
        external 
        notAllowed(to) 
        override
        returns(bool) 
    {
        uint allowance = allowed[from][msg.sender];

        require(allowance >= value, 'allowance too low');
        require(balances[from] >= value, 'token balance too low');

        allowed[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;

        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(
        address spender, 
        uint value
    ) 
        external 
        notAllowed(spender) 
        override
        returns(bool) 
    {
        allowed[msg.sender][spender] = value;
        
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseApproval(
        address spender,
        uint256 addedValue
    )
        external
        override
        returns (bool)
    {
    allowed[msg.sender][spender] += addedValue; 

    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
    }

    function decreaseApproval(
        address spender,
        uint256 subtractedValue
    )
        external
        override
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][spender];

        if (subtractedValue >= oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue - subtractedValue;
        }

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function allowance(
        address owner,
        address spender
    ) 
        external 
        view 
        override
        returns(uint) 
    {
        return allowed[owner][spender];
    }
    
    function balanceOf(address owner) external view override returns(uint) {
        return balances[owner];
    }

    function totalSupply() external view override returns(uint) {
      return _totalSupply;
    }
}

