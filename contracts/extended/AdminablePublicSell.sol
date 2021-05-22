// SPDX-License-Identifier: MIT

pragma solidity =0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Privilegeable.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/INFTPublicSeller.sol";

/**
 * @title AdminablePublicSell - whitelist administration
 * @author Pavel Bolhar <paul.bolhar@gmail.com>
 */
contract AdminablePublicSell is Ownable, Privilegeable {
    INFTPublicSeller public seller;

    constructor(INFTPublicSeller _nftPublicSeller) public {
        seller = _nftPublicSeller;
    }

    function transferTargetOwnership(address _newOwner) external onlyOwner {
        seller.transferOwnership(_newOwner);
    }

    function addToWhitelist(address _wallet) external anyAdmin {
        seller.addMember(_wallet);
    }

    function addManyToWhitelist(address[] calldata _wallets) external anyAdmin {
        uint256 walletsLength = _wallets.length;
        uint i = 0;
        for (i; i < walletsLength; i++) {
            if (!seller.isMember(_wallets[i])) {
                seller.addMember(_wallets[i]);
            }
        }
    }

    function removeFromWhitelist(address _wallet) external anyAdmin {
        seller.removeMember(_wallet);
    }

    function removeManyFromWhitelist(address[] calldata _wallets) external anyAdmin {
        seller.removeMembers(_wallets);
    }

    function ownerCall(bytes calldata _data) external onlyOwner {
        (bool success, ) = address(seller).call(_data);

        require(success, "Adminable: call filed");
    }

    function ownerCallAt(address _target, bytes calldata _data) external onlyOwner {
        (bool success, ) = _target.call(_data);

        require(success, "Adminable: call filed");
    }

    modifier anyAdmin() {
        require(owner() == _msgSender() || isAdmin(_msgSender()), "Adminable: caller is not the admin");
        _;
    }
}