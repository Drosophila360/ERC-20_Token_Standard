// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract ManualToken {
    // Public variables of the token
    string public name = "ManualToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 ether;
    address public owner;

    // This creates an array with all balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /*//////////////////////////////////////////////////////////////
                             ERRORS
     //////////////////////////////////////////////////////////////*/
    // This error is thrown when a transfer is attempted with insufficient balance
    error ManualToken__InsufficientBalance();
    // This error is thrown when a transfer is attempted to the zero address
    error ManualToken__InvalidAddress();
    // This error is thrown when a transfer is attempted with insufficient allowance
    error ManualToken__InsufficientAllowance();
    //This error is thrown when a non owner tries to call a function restricted to the owner
    error ManualToken__NotOwner();
    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ManualToken__NotOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    // Initializes contract with initial supply tokens to the creator of the contract
    constructor() {
        owner = msg.sender;
        // Give the creator all initial tokens
        balanceOf[msg.sender] = totalSupply;
        // Emit a Transfer event from the zero address on initial mint
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // Internal transfer, only can be called by this contract
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        if (_to == address(0x0)) {
            revert ManualToken__InvalidAddress();
        }
        // Check if the sender has enough
        if (balanceOf[_from] < _value) {
            revert ManualToken__InsufficientBalance();
        }
        // update balances
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        //emit Transfer event
        emit Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     * Send `_value` tokens to `_to` on behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        if (allowance[_from][msg.sender] < _value) {
            revert ManualToken__InsufficientAllowance();
        }
        // Update allowance and transfer the tokens
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowance[_from][msg.sender]);
        return true;
    }

    /**
     * Set allowance for other address
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Destroy tokens
     * Remove `_value` tokens from the system irreversibly
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) external returns (bool success) {
        if (balanceOf[msg.sender] < _value) {
            revert ManualToken__InsufficientBalance();
        }
        // update total supply and balance of the sender
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        // emit Burn event
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) external returns (bool success) {
        // Check if the targeted balance is enough
        if (balanceOf[_from] < _value) {
            revert ManualToken__InsufficientBalance();
        }
        // Check allowance
        if (allowance[_from][msg.sender] < _value) {
            revert ManualToken__InsufficientAllowance();
        }
        // Subtract from the targeted balance and update allowance
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        // Update totalSupply
        totalSupply -= _value;
        emit Burn(_from, _value);
        emit Approval(_from, msg.sender, allowance[_from][msg.sender]);
        return true;
    }

    function mint(address _to, uint256 _value) external onlyOwner returns (bool success) {
        if (_to == address(0x0)) {
            revert ManualToken__InvalidAddress();
        }
        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }
}
