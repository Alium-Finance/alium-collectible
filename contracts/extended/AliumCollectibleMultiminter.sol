// SPDX-License-Identifier: MIT

pragma solidity =0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../IAliumCollectible.sol";

/**
 * @title AliumCollectibleMultiminter - tokens issuer
 * @author Pavel Bolhar <paul.bolhar@gmail.com>
 */
contract AliumCollectibleMultiminter is IERC721Receiver, Ownable {

    /**
     * @dev Multi mint.
     *
     * Permission: Contract must have minter privilege.
     */
    function mintBatch(
        address token,
        address to,
        uint256 amount,
        uint256 _type
    )
        external
        onlyOwner
        returns (uint256[] memory items)
    {
        items = new uint256[](amount);
        uint tokenId;
        for (uint256 i = 0; i < amount; i++) {
            tokenId = IAliumCollectible(token).mint(address(this), _type);
            IAliumCollectible(token).safeTransferFrom(address(this), to, tokenId);
            items[i] = tokenId;
        }
    }

    /**
     * @dev See {ERC721TokenReceiver-onERC721Received}
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}