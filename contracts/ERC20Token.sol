// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

import "./IERC20Token.sol";
import "./SafeMath.sol";

contract ERC20Token is ERC20Interface {
    using SafeMath for uint;

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

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external override notAllowed(_to) returns (bool) {
        uint allowance = allowed[_from][msg.sender];

        require(allowance >= _value, "allowance too low");
        require(balances[_from] >= _value, "token balance too low");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

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
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

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
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
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
