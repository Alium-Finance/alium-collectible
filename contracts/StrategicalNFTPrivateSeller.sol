pragma solidity =0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "./Whitelist.sol";
import "./interfaces/IAliumCollectible.sol";
import "./interfaces/IERC20Optional.sol";

import {
    SafeMath,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title StrategicalNFTPrivateSeller - Private sell contract, get your NFT's
 * by crypto USD.
 *
 * @author Pavel Bolhar <paul.bolhar@gmail.com>
 */
contract StrategicalNFTPrivateSeller is IERC721Receiver, Ownable, Whitelist {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Bought(address token, address from, uint256 nftType, uint256 items, uint256 tokenId);
    event Deposited(address token, address from, uint256 amount);

    // @dev collections - list of resolved for sell collections types
    mapping(uint256 => bool) public resolvedNFTs;
    // @dev collections - list of resolved for sell stablecoins
    mapping(address => bool) public resolvedStablecoins;
    // @dev deposited - has address buy
    mapping(address => bool) public bought;

    // @dev nft - address of Alium NFT token
    address public nft;
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
        address[] memory _stablecoins,
        address[] memory _whitelist
    ) public {
        nft = _nft;
        founderDetails = _founderDetails;

        uint256 totalSupply;
        for (uint256 i = 0; i < _nftTypes.length; i++) {
            (, totalSupply, , , ) = IAliumCollectible(nft).getTypeInfo(
                _nftTypes[i]
            );

            require(
                totalSupply == 0,
                "token type was issued before from another minter"
            );
        }

        _addMembers(_whitelist);
        _addResolvedTypes(_nftTypes);
        _addResolvedStablecoins(_stablecoins);
    }

    /**
     * @dev Buy one NFT with specific `_type` NFT token by some `_amount`
     * of selected `_stablecoin`.
     * Stablecoin and type should be whitelisted.
     */
    function buy(
        address _stablecoin,
        uint256 _type,
        uint256 _amount
    ) external canParticipate {
        require(
            !bought[msg.sender],
            "Sales: attempts to purchase from the address have been exhausted"
        );
        require(
            resolvedStablecoins[_stablecoin],
            "Sales: stablecoin is not accepted"
        );
        require(resolvedNFTs[_type], "Sales: nft is not accepted");

        (uint256 price, uint256 totalSupply, uint256 maxSupply, , ) =
        IAliumCollectible(nft).getTypeInfo(_type);

        require(totalSupply < maxSupply, "Sales: all tokens bought");

        bought[msg.sender] = true;

        IERC20 token = IERC20(_stablecoin);
        uint256 decimals = uint256(IERC20Optional(_stablecoin).decimals());
        price = price.mul(10**decimals);

        require(
            token.allowance(msg.sender, address(this)) >= price,
            "Sales: required tokens amount not approved"
        );
        require(_amount == price, "Sales: amount more then item price");

        token.safeTransferFrom(_msgSender(), founderDetails, _amount);

        uint256 tokenId = IAliumCollectible(nft).mint(msg.sender, _type);

        emit Deposited(_stablecoin, msg.sender, _amount);
        emit Bought(nft, msg.sender, _type, 1, tokenId);
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
     * @dev Add collection types to white list.
     */
    function _addResolvedTypes(uint256[] memory _types) internal {
        uint256 l = _types.length;
        for (uint256 i = 0; i < l; i++) {
            resolvedNFTs[_types[i]] = true;
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
        }
    }

    /**
     * @dev Access modifier for whitelisted members.
     */
    modifier canParticipate() {
        require(isMember(msg.sender), "Seller: not from private list");
        _;
    }
}
