// SPDX-License-Identifier: MIT

pragma solidity =0.6.2;

interface IWhitelist {
    function isMember(address _member) external view returns (bool);
    function addMember(address _member) external;
    function addMembers(address[] calldata _members) external;
    function removeMember(address _member) external;
    function removeMembers(address[] calldata _members) external;
}
