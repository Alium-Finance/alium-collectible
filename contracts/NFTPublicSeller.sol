pragma solidity =0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IAliumCollectible.sol";
import "./IERC20Optional.sol";

import {
    SafeMath,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title NFTPublicSeller - Public sell contract, get your NFT's
 * by crypto stablecoins (tokens).
 *
 * @author Pavel Bolhar <paul.bolhar@gmail.com>
 */
contract NFTPublicSeller is IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Bought(address token, address from, uint256 nftType, uint256 items);
    event Deposited(address token, address from, uint256 amount);
    event NftTypeAdded(uint256 nftType);
    event NftTypeRemoved(uint256 nftType);
    event StablecoinAdded(address stablecoin);
    event StablecoinRemoved(address stablecoin);

    // @dev collections - list of resolved for sell collections types
    mapping(uint256 => bool) public resolvedNFTs;
    // @dev collections - list of resolved for sell stablecoins
    mapping(address => bool) public resolvedStablecoins;
    // @dev collections - users collections
    mapping(address => uint256[]) public collections;
    // @dev deposited - amount of deposited tokens
    mapping(address => mapping(address => uint256)) public deposited;

    // @dev nft - address of Alium NFT token
    address public nft;
    // @dev issuer - address of contract issuer
    address public issuer;
    // @dev issuer - address of founder
    address public founderDetails;

    /**
     * @dev Sets the values for {_nft}, {_founderDetails} and lists of {_nftTypes},
     * {_stablecoins}, {_whitelist}.
     */
    constructor(
        address _nft,
        address _founderDetails,
        uint256[] memory _nftTypes,
        address[] memory _stablecoins
    ) public {
        nft = _nft;
        issuer = msg.sender;
        founderDetails = _founderDetails;

        uint256 totalSupply;
        uint256 nominalPrice;
        uint256 maxSupply;
        for (uint256 i = 0; i < _nftTypes.length; i++) {
            (nominalPrice, totalSupply, maxSupply, , ) = IAliumCollectible(nft).getTypeInfo(
                _nftTypes[i]
            );

            require(
                nominalPrice != 0 && maxSupply > 0,
                "Public sell: token type is not initialized"
            );
            require(
                totalSupply == 0,
                "Public sell: token type was issued before from another minter"
            );
        }

        _addResolvedTypes(_nftTypes);
        _addResolvedStablecoins(_stablecoins);
    }

    /**
     * @dev Returns the length of the user's collection.
     */
    function getCollectionLength(address _who) public view returns (uint256) {
        return collections[_who].length;
    }

    /**
     * @dev See {NFTPrivateSeller-_buy}.
     */
    function buy(
        address _stablecoin,
        uint256 _type,
        uint256 _amount
    ) external {
        _buy(_stablecoin, _type, _amount);
    }

    /**
     * @dev See {NFTPrivateSeller-_buy} and {NFTPrivateSeller-_buyBatch}.
     */
    function buyBatch(
        address _stablecoin,
        uint256 _type,
        uint256 _amount,
        uint256 _items
    ) external {
        require(_items > 0, "Public sell: zero items, really?");

        if (_items == 1) {
            _buy(_stablecoin, _type, _amount);
        } else {
            _buyBatch(_stablecoin, _type, _amount, _items);
        }
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Repair any ERC20 supported interface tokens.
     *
     * @notice Tokens will be transferred to the current founder of contract.
     */
    function repairToken(address _stablecoin) public {
        IERC20 token = IERC20(_stablecoin);
        token.transfer(founderDetails, token.balanceOf(address(this)));
    }

    /**
     * @dev Set new founder credentials.
     *
     * Permission: only owner
     */
    function changeFounder(address _newFounder) public onlyOwner {
        founderDetails = _newFounder;
    }

    /**
     * @dev Buy one NFT with specific `_type` NFT token by some `_amount`
     * of selected `_stablecoin`.
     * Stablecoin and type should be whitelisted.
     */
    function _buy(
        address _stablecoin,
        uint256 _type,
        uint256 _amount
    ) internal {
        require(
            resolvedStablecoins[_stablecoin],
            "Public sell: stablecoin is not accepted"
        );
        require(resolvedNFTs[_type], "Public sell: nft is not accepted");

        (uint256 price, uint256 totalSupply, uint256 maxSupply, , ) =
            IAliumCollectible(nft).getTypeInfo(_type);

        require(totalSupply < maxSupply, "Public sell: all tokens bought");

        IERC20 token = IERC20(_stablecoin);
        uint256 decimals = uint256(IERC20Optional(_stablecoin).decimals());
        price = price.mul(10**decimals);

        require(
            token.allowance(msg.sender, address(this)) >= price,
            "Public sell: required tokens amount not approved"
        );
        require(_amount == price, "Public sell: amount more then item price");

        token.safeTransferFrom(_msgSender(), founderDetails, _amount);
        deposited[msg.sender][_stablecoin] += _amount;

        uint256 tokenId = IAliumCollectible(nft).mint(msg.sender, _type);
        collections[msg.sender].push(tokenId);

        emit Deposited(_stablecoin, msg.sender, _amount);
        emit Bought(nft, msg.sender, _type, 1);
    }

    /**
     * @dev Buy some `_items` NFT with specific `_type` NFT token
     * by some `_amount` of selected `_stablecoin`.
     * Stablecoin and type should be whitelisted.
     */
    function _buyBatch(
        address _stablecoin,
        uint256 _type,
        uint256 _amount,
        uint256 _items
    ) internal {
        require(
            resolvedStablecoins[_stablecoin],
            "Public sell: stablecoin is not accepted"
        );
        require(resolvedNFTs[_type], "Public sell: nft is not accepted");

        (uint256 price, uint256 totalSupply, uint256 maxSupply, , ) =
            IAliumCollectible(nft).getTypeInfo(_type);

        require(totalSupply < maxSupply, "Public sell: all tokens bought");
        require(
            totalSupply.add(_items) <= maxSupply,
            "Public sell: tokens limit is exceeded"
        );

        IERC20 token = IERC20(_stablecoin);
        uint256 decimals = uint256(IERC20Optional(_stablecoin).decimals());
        price = _items.mul(price.mul(10**decimals));

        require(
            token.allowance(msg.sender, address(this)) >= price,
            "Public sell: required tokens amount not approved"
        );
        require(_amount == price, "Public sell: amount more then item price");

        token.safeTransferFrom(_msgSender(), founderDetails, _amount);
        deposited[msg.sender][_stablecoin] += _amount;

        uint256 tokenId;
        uint256 lb = collections[msg.sender].length;
        for (uint256 i = 0; i < _items; i++) {
            tokenId = IAliumCollectible(nft).mint(msg.sender, _type);
            collections[msg.sender].push(tokenId);
        }

        require(
            collections[msg.sender].length == lb + _items,
            "Public sell: collection length invalid"
        );

        emit Deposited(_stablecoin, msg.sender, _amount);
        emit Bought(nft, msg.sender, _type, _items);
    }

    function addType(uint256 _type) external onlyOwner {
        require(!resolvedNFTs[_type], "Public sell: type resolved");

        (
            uint256 nominalPrice,
            uint256 totalSupply,
            uint256 maxSupply,
            ,
        ) = IAliumCollectible(nft).getTypeInfo(
            _type
        );

        require(
            nominalPrice != 0 && maxSupply > 0,
            "Public sell: token type is not initialized"
        );
        require(
            totalSupply == 0,
            "Public sell: token type was issued before from another minter"
        );

        resolvedNFTs[_type] = true;
        emit NftTypeAdded(_type);
    }

    function removeType(uint256 _type) external onlyOwner {
        require(resolvedNFTs[_type], "Public sell: type not resolved");

        resolvedNFTs[_type] = false;
        emit NftTypeRemoved(_type);
    }

    function addStablecoin(address _address) external onlyOwner {
        require(!resolvedStablecoins[_address], "Public sell: token resolved");

        resolvedStablecoins[_address] = true;
        emit StablecoinAdded(_address);
    }

    function removeStablecoin(address _address) external onlyOwner {
        require(resolvedStablecoins[_address], "Public sell: token not resolved");

        resolvedStablecoins[_address] = false;
        emit StablecoinRemoved(_address);
    }

    /**
     * @dev Add collection types to white list.
     */
    function _addResolvedTypes(uint256[] memory _types) internal {
        uint256 l = _types.length;
        for (uint256 i = 0; i < l; i++) {
            resolvedNFTs[_types[i]] = true;
            emit NftTypeAdded(_types[i]);
        }
    }

    /**
     * @dev Add stablecons to white list.
     *
     * Requirements:
     *
     * - `_stablecoins` list of tokens with price 1:1 to USD.
     */
    function _addResolvedStablecoins(address[] memory _stablecoins) internal {
        uint256 l = _stablecoins.length;
        for (uint256 i = 0; i < l; i++) {
            resolvedStablecoins[_stablecoins[i]] = true;
            emit StablecoinAdded(_stablecoins[i]);
        }
    }
}
