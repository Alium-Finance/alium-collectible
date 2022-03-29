pragma solidity =0.6.2;

interface IAliumCollectible {
    function mint(address to, uint256 _type) external returns (uint256);

    function setMinterOnly(address _minter, uint256 _type) external;

    function addMinter(address _minter) external;

    function transfer(address _to, uint256 _tokenId) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address _to, uint256 _tokenId) external returns (bool);

    function owner() external view returns (address);

    function getTypeInfo(uint256 _type)
        external
        view
        returns (
            uint256 nominalPrice,
            uint256 totalSupply,
            uint256 maxSupply,
            string memory info,
            address minterOnly
        );

    function getTokenType(uint256 tokenId) external view returns (uint256);

    function burn(uint256 tokenId) external;
}
