pragma solidity =0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./AliumCollectionMintable.sol";

pragma experimental ABIEncoderV2;

contract AliumAchievementCollectible is ERC721, AliumCollectionMintable {
    Counters.Counter private _tokenIdTracker;

    struct TokenData {
        string description;
    }

    mapping(uint256 => TokenData) internal _tokens;

    /**
     * @dev Preset the values NFT token.
     * See {ERC721-constructor}.
     */
    constructor() public ERC721("Alium Achievements Collection", "ALMACH") {}

    /**
     * @dev See {ERC71-_exists}.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev Returns token type by token id `_tokenId`.
    */
    function getTokenInfo(uint256 _tokenId) public view returns (string memory) {
        return _tokens[_tokenId].description;
    }

    /**
     * @dev Add new user with MINTER_ROLE permission.
     *
     * Permission: onlyAdmin
     */
    function addMinter(address _newMinter) public onlyAdmin {
        _setupRole(MINTER_ROLE, _newMinter);
    }

    /**
     * @dev Mint one NFT token to specific address `_to` with specific type id `_type`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function mint(address _to) public returns (uint256) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "AliumAchievement: must have minter role to mint"
        );

        Counters.increment(_tokenIdTracker);
        _safeMint(_to, Counters.current(_tokenIdTracker));

        return Counters.current(_tokenIdTracker);
    }

    /**
      * @dev Mint one NFT token to specific address `_to` with specific type id `_type`.
      *
      * Returns a boolean value indicating whether the operation succeeded.
      *
      * Emits a {Transfer} event.
      */
    function mintBatch(address _to, uint256 _items) public returns (uint256[] memory ids) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "AliumAchievement: must have minter role to mint"
        );
        require(
            _items > 1,
            "AliumAchievement: must have minter role to mint"
        );

        ids = new uint256[](_items);
        for (uint256 i = 0; i < _items; i++) {
            Counters.increment(_tokenIdTracker);
            _safeMint(_to, Counters.current(_tokenIdTracker));
            ids[i] = Counters.current(_tokenIdTracker);
        }
    }

    function setTokenDataBatch(uint256[] memory _tokenIds, string[] memory _descs) public returns (bool) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "AliumAchievement: must have minter role to mint"
        );

        uint256 idsLen = _tokenIds.length;

        require(
            idsLen == _descs.length,
            "AliumAchievement: not equal data sent"
        );

        uint256 i = 0;
        for (i; i < idsLen; i++) {
            _tokens[_tokenIds[i]].description = _descs[i];
        }

        return true;
    }

    /**
     * @dev Moves one NFT token to specific address `_to` with specific token id `_tokenId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _to, uint256 _tokenId) public returns (bool) {
        _transfer(address(this), _to, _tokenId);

        return true;
    }

    /**
     * @dev See {ERC71-_burn}.
     */
    function burn(uint256 _tokenId) public {
        require(ERC721.ownerOf(_tokenId) == _msgSender(), "not owner");

        _burn(_tokenId);
    }

    /**
     * @dev See {ERC71-_setTokenURI}.
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyAdmin
    {
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @dev See {ERC71-_setBaseURI}.
     */
    function setBaseURI(string memory _baseURI) public onlyAdmin {
        _setBaseURI(_baseURI);
    }

    /**
     * @dev See {ERC71-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

}
