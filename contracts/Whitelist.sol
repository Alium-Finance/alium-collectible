pragma solidity =0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Whitelist
 * @author Alberto Cuesta Canada
 * @dev Implements a simple whitelist of addresses.
 */
contract Whitelist is Ownable {
    event MemberAdded(address member);
    event MemberRemoved(address member);

    mapping(address => bool) private members;

    /**
     * @dev The contract constructor.
     */
    constructor() public Ownable() {}

    /**
     * @dev A method to verify whether an address is a member of the whitelist
     * @param _member The address to verify.
     * @return Whether the address is a member of the whitelist.
     */
    function isMember(address _member) public view returns (bool) {
        return members[_member];
    }

    /**
     * @dev A method to add a member to the whitelist
     * @param _member The member to add as a member.
     */
    function addMember(address _member) external onlyOwner {
        require(!isMember(_member), "Whitelist: Address is member already");

        members[_member] = true;
        emit MemberAdded(_member);
    }

    /**
     * @dev A method to add a member to the whitelist
     * @param _members The members to add as a member.
     */
    function addMembers(address[] calldata _members) external onlyOwner {
        _addMembers(_members);
    }

    /**
     * @dev A method to remove a member from the whitelist
     * @param _member The member to remove as a member.
     */
    function removeMember(address _member) external onlyOwner {
        require(isMember(_member), "Whitelist: Not member of whitelist");

        delete members[_member];
        emit MemberRemoved(_member);
    }

    /**
     * @dev A method to remove a members from the whitelist
     * @param _members The members to remove as a member.
     */
    function removeMembers(address[] calldata _members) external onlyOwner {
        _removeMembers(_members);
    }

    function _addMembers(address[] memory _members) internal {
        uint256 l = _members.length;
        uint256 i;
        for (i; i < l; i++) {
            require(
                !isMember(_members[i]),
                "Whitelist: Address is member already"
            );

            members[_members[i]] = true;
            emit MemberAdded(_members[i]);
        }
    }

    function _removeMembers(address[] memory _members) internal {
        uint256 l = _members.length;
        uint256 i;
        for (i; i < l; i++) {
            require(
                isMember(_members[i]),
                "Whitelist: Address is no member"
            );

            delete members[_members[i]];
            emit MemberRemoved(_members[i]);
        }
    }
}
