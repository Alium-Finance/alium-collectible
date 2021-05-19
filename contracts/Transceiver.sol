pragma solidity ^0.6.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface ITransceiver {
    function freeze(
        address beneficiary,
        uint256 amount,
        uint8 vestingPlanId
    ) external returns (bool success);
}

contract Roles is Ownable {
    event MemberAdded(address member, uint roleType);
    event MemberRemoved(address member, uint roleType);

    enum Role {
        RECEIVER,
        TRANSMITTER
    }

    mapping (address => mapping (uint256 => bool)) private members;

    /**
     * @dev The contract constructor.
     */
    constructor() public Ownable() {}

    /**
     * @dev A method to verify whether an address is a member of the whitelist
     * @param _member The address to verify.
     * @return Whether the address is a member of the whitelist.
     */
    function isReceiver(address _member) public view returns (bool) {
        return members[_member][uint256(Role.RECEIVER)];
    }

    function isTransmitter(address _member) public view returns (bool) {
        return members[_member][uint256(Role.TRANSMITTER)];
    }

    /**
     * @dev A method to add a member to the whitelist
     * @param _member The member to add as a member.
     */
    function addMember(address _member, uint256 _role) external onlyOwner {
        require(!members[_member][_role], "Roles: Address is member already");

        members[_member][_role] = true;
        emit MemberAdded(_member, uint256(_role));
    }

    function removeMember(address _member, uint256 _role) external onlyOwner {
        require(members[_member][_role], "Roles: Not member of role");

        delete members[_member][_role];
        emit MemberRemoved(_member, uint256(_role));
    }

    modifier onlyReceiver() {
        require(isReceiver(_msgSender()), "Roles: caller is not the receiver");
        _;
    }

    modifier onlyTransmitter() {
        require(isTransmitter(_msgSender()), "Roles: caller is not the owner");
        _;
    }
}

// Set as freezer
contract Transceiver is ITransceiver, Roles {

    // address that we should call on type receive
    mapping (uint256 => address) private _dests;

    function linkTypeToAddress(uint256 _typeId, address _dest) external onlyOwner {
        _dests[_typeId] = _dest;
    }

    function freeze(
        address beneficiary,
        uint256 amount,
        uint8 vestingPlanId
    )
    external
    override
    onlyReceiver
    returns (bool success)
    {
        require(_dests[vestingPlanId] != address(0), "Transceiver: type not initialized");
        require(isTransmitter(_dests[vestingPlanId]), "Transceiver: transmitter not found");

        ITransceiver(_dests[vestingPlanId]).freeze(beneficiary, amount, vestingPlanId);
        return true;
    }
}