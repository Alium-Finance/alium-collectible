// SPDX-License-Identifier: MIT

pragma solidity =0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../IAliumAchievement.sol";

contract AliumArchievementMultiminter is IERC721Receiver, Ownable {

    event Minted(address to, uint256 tokenId);

    function mintBatch(
        address token,
        address[] calldata to,
        uint256[] calldata amount
    )
        external
        onlyOwner
    {
        require(token != address(0), "Zero token address");
        require(to.length == amount.length, "Wrong data passed");

        uint len = to.length;
        uint tokenId;
        for (uint256 i = 0; i < len; i++) {
            if (amount[i] == 0) {
                require(false, "Zero tokens mint");
            } else if (amount[i] == 1) {
                tokenId = IAliumAchievement(token).mint(address(this));
                IAliumAchievement(token).safeTransferFrom(address(this), to[i], tokenId);
                emit Minted(to[i], tokenId);
            } else if (amount[i] > 1) {
                for (uint256 ii = 0; ii < amount[i]; ii++) {
                    tokenId = IAliumAchievement(token).mint(address(this));
                    IAliumAchievement(token).safeTransferFrom(address(this), to[i], tokenId);
                    emit Minted(to[i], tokenId);
                }
            }
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