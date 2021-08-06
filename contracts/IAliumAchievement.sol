pragma solidity =0.6.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface IAliumAchievement is IERC721, IERC721Metadata, IERC721Enumerable {
    function mint(address _to) external returns (uint256);
}
