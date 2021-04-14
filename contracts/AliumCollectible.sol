pragma solidity =0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./AliumCollectionMintable.sol";

/**
 * @title AliumCollectible - Collectible token implementation,
 * from Alium project, based on OpenZeppelin eip-721 implementation.
 *
 * @author Pavel Bolhar <paul.bolhar@gmail.com>
 */
contract AliumCollectible is ERC721, AliumCollectionMintable {
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _tokenTypes;

    struct TypeData {
        address minterOnly;
        string info;
        uint256 nominalPrice;
        uint256 totalSupply;
        uint256 maxSupply;
    }

    struct TokenData {
        uint256 hasType;
    }

    mapping(uint256 => TypeData) internal _types;
    mapping(uint256 => TokenData) internal _tokens;

    /**
     * @dev Preset the values NFT token.
     * See {ERC721-constructor}.
     */
    constructor() public ERC721("Alium Cards Collection", "ALMNFT") {}

    /**
     * @dev Returns data about token collection by type id `_typeId`.
    */
    function getTypeInfo(uint256 _typeId)
        public
        view
        returns (
            uint256 nominalPrice,
            uint256 totalSupply,
            uint256 maxSupply,
            string memory info,
            address minterOnly
        )
    {
        TypeData memory t = _types[_typeId];

        return (
            t.nominalPrice,
            t.totalSupply,
            t.maxSupply,
            t.info,
            t.minterOnly
        );
    }

    /**
     * @dev Returns token type by token id `_tokenId`.
    */
    function getTokenType(uint256 _tokenId) public view returns (uint256) {
        return _tokens[_tokenId].hasType;
    }

    /**
     * @dev See {ERC71-_exists}.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
      * @dev Create new token collection, with uniq id.
      *
      * Permission: onlyAdmin
      *
      * @param _nominalPrice - nominal price per item, should be set in USD,
      *        with decimal zero
      * @param _maxTotal - maximum total amount items in collection
      * @param _info - general information about collection
      */
    function createNewTokenType(
        uint256 _nominalPrice,
        uint256 _maxTotal,
        string memory _info
    )
        public
        onlyAdmin
    {
        require(_nominalPrice != 0, "AliumCollectible: nominal price is zero");

        Counters.increment(_tokenTypes);

        TypeData memory t;
        t.nominalPrice = _nominalPrice;
        t.maxSupply = _maxTotal;
        t.info = _info;

        _types[Counters.current(_tokenTypes)] = t;
    }

    /**
     * @dev Setter for lock minter rights by `_minter` and `_type`.
     *
     * Permission: onlyAdmin
     */
    function setMinterOnly(address _minter, uint256 _type) external onlyAdmin {
        require(
            _types[_type].minterOnly == address(0),
            "AliumCollectible: minter locked yet"
        );

        _types[_type].minterOnly = _minter;
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
    function mint(address _to, uint256 _type) public returns (uint256) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "AliumCollectible: must have minter role to mint"
        );
        require(
            _type <= Counters.current(_tokenTypes),
            "AliumCollectible: type not exist"
        );

        if (_types[_type].minterOnly != address(0)) {
            require(
                _types[_type].minterOnly == _msgSender(),
                "AliumCollectible: minting locked by another account"
            );
        }

        Counters.increment(_tokenIdTracker);
        _safeMint(_to, Counters.current(_tokenIdTracker));
        _tokens[Counters.current(_tokenIdTracker)].hasType = _type;

        _types[_type].totalSupply += 1;

        require(
            _types[_type].totalSupply <= _types[_type].maxSupply,
            "AliumCollectible: max supply reached"
        );

        return Counters.current(_tokenIdTracker);
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
