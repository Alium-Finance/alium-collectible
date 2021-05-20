pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";

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