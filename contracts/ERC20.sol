// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NB: We followed the official ERC-20 standard token creation guides
// References from:
// https://eips.ethereum.org/EIPS/eip-20
// https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
contract Token {
    // State Variables for token creation
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Declaring mappings
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Declaring events..
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * (10**(decimals));
        balanceOf[msg.sender] = totalSupply;
    }

    modifier invalidAddress(address _address) {
        require(_address != address(0), "Invalid Address");
        _;
    }

    function transfer(address _to, uint256 _value) public invalidAddress(_to) returns (bool success){
        require(
            balanceOf[msg.sender] >= _value, "Oops, Insufficient Token"
        );
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public invalidAddress(_spender) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(
            balanceOf[_from] >= _value, "Oops, Insufficient Token to complete Transfer"
        );
        require(
            allowance[_from][msg.sender] >= _value, "Oops, Transfer is not allowed"
        );

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);

        return true;
    }
}