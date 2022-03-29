pragma solidity =0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IAliumCollectible.sol";
import "./interfaces/INFTPrivateSeller.sol";
import "./interfaces/IERC20Optional.sol";
import "./interfaces/IAliumVesting.sol";

import {
    SafeMath,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title NFTPrivateExchanger - Special exchange contract
 * where NFT will be replaced by native ERC20 and
 * achievement tokens.
 *
 * @author Pavel Bolhar <paul.bolhar@gmail.com>
 */
contract NFTPrivateExchanger is IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public vesting;
    address public nft;
    address public achievement;

    mapping (uint => bool) public charged;
    // @dev collections - list of resolved for sell collections types
    mapping(uint256 => bool) public resolvedNFTs;
    // @dev type id -> tokens per item
    mapping(uint256 => uint256) public rewards;

    event Charged(uint tokenId, uint tokens);
    event RewardChanged(uint typeId, uint newReward);

    /**
     * @dev Sets the values for {_vesting}, {_privateNFT}, {_achievementNFT} and
     * lists of {_nftTypes}
     */
    constructor(
        IAliumVesting _vesting,
        IERC721 _privateNFT,
        IERC721 _achievementNFT,
        uint256[] memory _nftTypes
    ) public {
        vesting = address(_vesting);
        nft = address(_privateNFT);
        achievement = address(_achievementNFT);

        _typeResolve(_nftTypes, true);
    }

    /**
     * @dev Burn your token and unlock facilities on vesting contract,
     * like a bonus you will receive achievement token.
     */
    function charge(uint _tokenId) public {
        require(!charged[_tokenId], "PrivateExchanger: Charged");

        uint tokenType = IAliumCollectible(nft).getTokenType(_tokenId);

        require(resolvedNFTs[tokenType], "PrivateExchanger: Token type not resolved");
        require(rewards[tokenType] != 0, "PrivateExchanger: No reward");

        IERC721(nft).safeTransferFrom(msg.sender, address(0xdead), _tokenId);

        charged[_tokenId] = true;

        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = _tokenId;

        IERC721(achievement).approve(msg.sender, _tokenId);
        IERC721(achievement).safeTransferFrom(address(this), msg.sender, _tokenId);
        IAliumVesting(vesting).freeze(msg.sender, rewards[tokenType], uint8(tokenType));
    }

    /**
     * @dev {NFTPrivateExchanger-charge} with the possibility of batch processing.
     */
    function chargeBatch(uint[] memory _tokenIds, uint _type) public {
        require(resolvedNFTs[_type], "PrivateExchanger: Token type not resolved");
        require(rewards[_type] != 0, "PrivateExchanger: No reward");

        uint256 idsLen = _tokenIds.length;
        for (uint256 i = 0; i < idsLen; i++) {
            require(!charged[_tokenIds[i]], "PrivateExchanger: Found charged");
            require(
                IAliumCollectible(nft).getTokenType(_tokenIds[i]) == _type,
                "PrivateExchanger: Found wrong type in passed collection"
            );

            IERC721(nft).safeTransferFrom(msg.sender, address(0xdead), _tokenIds[i]);

            charged[_tokenIds[i]] = true;

            IERC721(achievement).approve(msg.sender, _tokenIds[i]);
            IERC721(achievement).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        uint256 amount = rewards[_type].mul(idsLen);
        IAliumVesting(vesting).freeze(msg.sender, amount, uint8(_type));
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

    /**
     * @dev Add collection types to white list.
     */
    function addResolvedTypes(uint256[] memory _types) public onlyOwner {
        _typeResolve(_types, true);
    }

    /**
     * @dev Add collection types to white list.
     */
    function removeResolvedTypes(uint256[] memory _types) public onlyOwner {
        _typeResolve(_types, false);
    }

    /**
     * @dev Add type reward.
     */
    function setTypeReward(uint256 _type, uint256 _amount) public onlyOwner {
        rewards[_type] = _amount;
        emit RewardChanged(_type, _amount);
    }

    /**
     * @dev Internal white list state mutator.
     */
    function _typeResolve(uint256[] memory _types, bool _resolve) private {
        uint256 l = _types.length;
        for (uint256 i = 0; i < l; i++) {
            resolvedNFTs[_types[i]] = _resolve;
        }
    }
}
