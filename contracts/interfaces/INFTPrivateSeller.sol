pragma solidity =0.6.2;

interface INFTPrivateSeller {
    function resolvedNFTs(uint nftType) external view returns (bool);
}
