// SPDX-License-Identifier: MIT

pragma solidity =0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Privilegeable is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint256;

    event PrivilegeGranted(address indexed admin);
    event PrivilegeRevoked(address indexed admin);

    mapping(address => bool) private _privilegeTable;

    constructor() internal {
        _addAdmin(_msgSender());
    }

    function isAdmin(address _who) public view returns (bool) {
        return _privilegeTable[_who];
    }

    function addAdmin(address _admin) external onlyOwner returns (bool) {
        require(_admin != address(0), "Admin address cannot be 0");
        return _addAdmin(_admin);
    }

    function removeAdmin(address _admin) external onlyOwner returns (bool) {
        require(_admin != address(0), "Admin address cannot be 0");
        _privilegeTable[_admin] = false;
        emit PrivilegeRevoked(_admin);

        return true;
    }

    function _addAdmin(address _admin) internal returns (bool) {
        _privilegeTable[_admin] = true;
        emit PrivilegeGranted(_admin);

        return true;
    }

    modifier onlyAdmin() {
        require(
            _privilegeTable[msg.sender],
            "Privilegeable: caller is not the owner"
        );
        _;
    }
}
