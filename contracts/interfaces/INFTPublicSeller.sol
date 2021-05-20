pragma solidity =0.6.2;

import "./IOwnable.sol";
import "./IWhitelist.sol";

interface INFTPublicSeller is IOwnable, IWhitelist {
    function resolvedNFTs(uint nftType) external view returns (bool);
}
