// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20Token.sol";

contract ERC20Token is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;

    modifier notAllowed(address to) {
        require(to != address(0x00), "Zero Address Not Allowed!");
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

    function transfer(address _to, uint _value)
        external
        override
        notAllowed(_to)
        returns (bool)
    {
        require(balances[msg.sender] >= _value, "token balance too low");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external override notAllowed(_to) returns (bool) {
        uint _allowance = allowed[_from][msg.sender];

        require(_allowance >= _value, "allowance too low");
        require(balances[_from] >= _value, "token balance too low");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value)
        external
        override
        notAllowed(_spender)
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseApproval(address _spender, uint _addedValue)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] += _addedValue;

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) external view override returns (uint) {
        return balances[_owner];
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }
}
