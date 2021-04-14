import BN from "bn.js";

import { ethers } from "hardhat";
import { Signer } from "ethers";
import { assert, expect } from "chai";

import chai from "chai";

import { solidity } from "ethereum-waffle";
chai.use(solidity);

const {
    expectEvent,
    expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

const BURN_ADDRESS = '0x000000000000000000000000000000000000dEaD'

const deployAliumCollectible = async () => {
    const AliumCollectible = await ethers.getContractFactory("AliumCollectible");
    return AliumCollectible.deploy();
}

const deployAliumAchievementCollectible = async () => {
    const AliumAchievementCollectible = await ethers.getContractFactory("AliumAchievementCollectible");
    return AliumAchievementCollectible.deploy();
}

const deployNFTPrivateExchanger = async (
    aliumToken: string,
    privateNFT: string,
    achievementNFT: string,
    nftTypes: Array<number>
) => {
    const NFTPrivateExchanger = await ethers.getContractFactory("NFTPrivateExchanger");
    return NFTPrivateExchanger.deploy(
      aliumToken,
      privateNFT,
      achievementNFT,
      nftTypes
    );
}

interface TokenTypeData {
    prices: Array<number>,
    amounts: Array<number>
}

async function batchCreateTokenTypes(aliumNft: any, data: TokenTypeData) {
    if (data.prices.length != data.amounts.length) {
        throw new Error('batch create token types, wrong config')
    }

    for (let i = 0; i < data.prices.length; i++) {
        await aliumNft.createNewTokenType(data.prices[i], data.amounts[i], `test type collection ${i}`)
    }
}

describe("NFTPrivateSeller", function () {
    let accounts: Signer[];

    let OWNER: any
    let NEW_OWNER: any
    let FOUNDER: any
    let NEW_FOUNDER: any
    let BUYER: any

    let OWNER_SIGNER: any
    let NEW_OWNER_SIGNER: any
    let FOUNDER_SIGNER: any
    let NEW_FOUNDER_SIGNER: any
    let BUYER_SIGNER: any

    let ALM: any
    let vesting: any
    let aliumNft: any;
    let aliumArchNft: any;

    before('Configuration',async function () {
        accounts = await ethers.getSigners();

        OWNER_SIGNER = accounts[0];
        FOUNDER_SIGNER = accounts[1];
        BUYER_SIGNER = accounts[2];
        NEW_OWNER_SIGNER = accounts[3];
        NEW_FOUNDER_SIGNER = accounts[4];

        OWNER = await OWNER_SIGNER.getAddress()
        NEW_OWNER = await NEW_OWNER_SIGNER.getAddress()
        FOUNDER = await FOUNDER_SIGNER.getAddress()
        NEW_FOUNDER = await NEW_FOUNDER_SIGNER.getAddress()
        BUYER = await BUYER_SIGNER.getAddress()
    });

    describe("Exchange", function () {
        let testCollNomPrice = 100_000 // in usd
        let testColl2NomPrice = 50_000 // in usd
        let testColl3NomPrice = 15_000 // in usd

        let testCollCardsAmount = 11;
        let testColl2CardsAmount = 10;
        let testColl3CardsAmount = 40;

        let rewardType1 = 1_000_000
        let rewardType2 = 400_000
        let rewardType3 = 100_000

        let achievementMessage = 'I was an elite evangelist for the Alium Finance project'

        beforeEach('exchange',async function () {
            const BEP20Mock = await ethers.getContractFactory("BEP20Mock");
            ALM = await BEP20Mock.deploy('Alium Token', 'ALM');

            const MockVesting = await ethers.getContractFactory("MockVesting");
            vesting = await MockVesting.deploy();

            aliumNft = await deployAliumCollectible();

            await batchCreateTokenTypes(aliumNft, {
                prices: [
                  testCollNomPrice,
                  testColl2NomPrice,
                  testColl3NomPrice,
                ],
                amounts: [
                  testCollCardsAmount,
                  testColl2CardsAmount,
                  testColl3CardsAmount,
                ]
            })
            await aliumNft.addMinter(OWNER);

            aliumArchNft = await deployAliumAchievementCollectible();

            await aliumArchNft.addMinter(OWNER);
        });

        it("should change and burn 1 NFT token to X ALMs and 1 ARCH NFT", async function () {
            let expectedTokenType = 1
            let expectedChargedTokenId = 1
            let nftTypes = [1, 2, 3]

            let exchanger = await deployNFTPrivateExchanger(
                vesting.address,
                aliumNft.address,
                aliumArchNft.address,
                nftTypes
            )

            let expectedRewardByType1 = (
              new BN(
                rewardType1
              )
            ).mul(new BN(10).pow(new BN(18)));
            let expectedReward = expectedRewardByType1;

            // set reward for expected type
            await exchanger.connect(OWNER_SIGNER).setTypeReward(expectedTokenType, expectedRewardByType1.toString());

            // mint arch nft to exchanger
            await aliumArchNft.connect(OWNER_SIGNER).mint(exchanger.address)

            assert.equal((await aliumArchNft.ownerOf(1)).toString(), exchanger.address, "arch. NFT id 1 not exchanger")

            // set arch nft data
            let tokenIDs = [1]
            let descs = [achievementMessage]

            await aliumArchNft.connect(OWNER_SIGNER).setTokenDataBatch(tokenIDs, descs)

            // mint nft cards (type {1}) to buyer
            await aliumNft.connect(OWNER_SIGNER).mint(BUYER, expectedTokenType)

            assert.equal((await aliumNft.exists(1)), true, "NFT id 1 not exist")
            assert.equal(await aliumNft.ownerOf(1), BUYER, "NFT id 1 not buyer")
            assert.equal((await aliumNft.balanceOf(BUYER)), 1, "Buyer balance 1")

            // charge

            await aliumNft.connect(BUYER_SIGNER).approve(exchanger.address, expectedChargedTokenId)
            let chargeResult = await exchanger.connect(BUYER_SIGNER).charge(expectedChargedTokenId)

            assert.equal((await aliumNft.ownerOf(1)), BURN_ADDRESS, "NFT id 1 not burned")
            assert.equal((await aliumArchNft.ownerOf(1)), BUYER, "arch. NFT id 1 not delivered")

            await expect(chargeResult)
              .to.emit(vesting, 'Frozen')
              .withArgs(BUYER, expectedReward.toString(), expectedTokenType);
        });

        it("should change and burn 2 NFT token to X ALMs and 2 ARCH NFT", async function () {
            let expectedTokenType = 1
            let expectedItems = 2;
            let expectedChargedTokenId = 1
            let expectedChargedTokenId2 = 2
            let nftTypes = [1, 2, 3]

            let exchanger = await deployNFTPrivateExchanger(
              vesting.address,
              aliumNft.address,
              aliumArchNft.address,
              nftTypes
            )

            let expectedRewardByType1 = (
              new BN(
                rewardType1
              )
            ).mul(new BN(10).pow(new BN(18)));
            let expectedReward = expectedRewardByType1.mul(new BN(expectedItems));

            // set reward for expected type
            await exchanger.connect(OWNER_SIGNER).setTypeReward(expectedTokenType, expectedRewardByType1.toString());

            // mint 2 arch nft to exchanger
            await aliumArchNft.connect(OWNER_SIGNER).mint(exchanger.address)
            await aliumArchNft.connect(OWNER_SIGNER).mint(exchanger.address)

            assert.equal((await aliumArchNft.ownerOf(1)).toString(), exchanger.address, "arch. NFT id 1 not exchanger")

            // set arch nft data
            let tokenIDs = [1]
            let descs = [achievementMessage]

            await aliumArchNft.connect(OWNER_SIGNER).setTokenDataBatch(tokenIDs, descs)

            // mint 2 nft cards (type {1}) to buyer
            await aliumNft.connect(OWNER_SIGNER).mint(BUYER, expectedTokenType)
            await aliumNft.connect(OWNER_SIGNER).mint(BUYER, expectedTokenType)

            assert.equal((await aliumNft.exists(1)), true, "NFT id 1 not exist")
            assert.equal((await aliumNft.exists(2)), true, "NFT id 2 not exist")
            assert.equal(await aliumNft.ownerOf(1), BUYER, "NFT id 1 not buyer")
            assert.equal(await aliumNft.ownerOf(2), BUYER, "NFT id 2 not buyer")
            assert.equal((await aliumNft.balanceOf(BUYER)), 2, "Buyer balance 2")

            // charge

            await aliumNft.connect(BUYER_SIGNER).setApprovalForAll(exchanger.address, true)
            let chargeResult = await exchanger.connect(BUYER_SIGNER).chargeBatch(
                [
                    expectedChargedTokenId,
                    expectedChargedTokenId2
                ],
                expectedTokenType
            )

            assert.equal((await aliumNft.ownerOf(1)), BURN_ADDRESS, "NFT id 1 not burned")
            assert.equal((await aliumNft.ownerOf(2)), BURN_ADDRESS, "NFT id 2 not burned")
            assert.equal((await aliumArchNft.ownerOf(1)), BUYER, "arch. NFT id 1 not delivered")
            assert.equal((await aliumArchNft.ownerOf(2)), BUYER, "arch. NFT id 2 not delivered")

            await expect(chargeResult)
              .to.emit(vesting, 'Frozen')
              .withArgs(BUYER, expectedReward.toString(), expectedTokenType);
        });

        it("should fail on charges", async function () {
            let expectedTokenType = 1
            let expectedTokenType2 = 2
            let notExpectedTokenType = 4
            let expectedChargedTokenId = 1
            let expectedChargedTokenId2 = 2
            let notExpectedChargedTokenId = 3

            let testColl4NomPrice = 11_000
            let testColl4CardsAmount = 50

            await batchCreateTokenTypes(aliumNft, {
                prices: [
                    testColl4NomPrice,
                ],
                amounts: [
                    testColl4CardsAmount,
                ]
            })

            let nftTypes = [1, 2, 3]

            let exchanger = await deployNFTPrivateExchanger(
              vesting.address,
              aliumNft.address,
              aliumArchNft.address,
              nftTypes
            )

            let expectedRewardByType1 = (
              new BN(
                rewardType1
              )
            ).mul(new BN(10).pow(new BN(18)));
            let expectedRewardByType2 = (
              new BN(
                rewardType2
              )
            ).mul(new BN(10).pow(new BN(18)));

            // set reward for expected type
            await exchanger.connect(OWNER_SIGNER).setTypeReward(expectedTokenType, expectedRewardByType1.toString());
            await exchanger.connect(OWNER_SIGNER).setTypeReward(expectedTokenType, expectedRewardByType2.toString());

            // mint 3 arch nft to exchanger
            await aliumArchNft.connect(OWNER_SIGNER).mint(exchanger.address)
            await aliumArchNft.connect(OWNER_SIGNER).mint(exchanger.address)
            await aliumArchNft.connect(OWNER_SIGNER).mint(exchanger.address)

            assert.equal((await aliumArchNft.ownerOf(1)).toString(), exchanger.address, "arch. NFT id 1 not exchanger")

            // set arch nft data
            let tokenIDs = [1]
            let descs = [achievementMessage]

            await aliumArchNft.connect(OWNER_SIGNER).setTokenDataBatch(tokenIDs, descs)

            // mint 2 nft cards (type {1, 2, 4}) to buyer
            await aliumNft.connect(OWNER_SIGNER).mint(BUYER, expectedTokenType)
            await aliumNft.connect(OWNER_SIGNER).mint(BUYER, expectedTokenType2)
            await aliumNft.connect(OWNER_SIGNER).mint(BUYER, notExpectedTokenType)

            assert.equal((await aliumNft.exists(1)), true, "NFT id 1 not exist")
            assert.equal((await aliumNft.exists(2)), true, "NFT id 2 not exist")
            assert.equal((await aliumNft.exists(3)), true, "NFT id 2 not exist")
            assert.equal(await aliumNft.ownerOf(1), BUYER, "NFT id 1 not buyer")
            assert.equal(await aliumNft.ownerOf(2), BUYER, "NFT id 2 not buyer")
            assert.equal(await aliumNft.ownerOf(3), BUYER, "NFT id 2 not buyer")
            assert.equal((await aliumNft.balanceOf(BUYER)), 3, "Buyer balance 3")

            // charge

            await aliumNft.connect(BUYER_SIGNER).setApprovalForAll(exchanger.address, true)

            await expectRevert(
                exchanger.connect(BUYER_SIGNER).chargeBatch(
                  [
                      expectedChargedTokenId,
                      expectedChargedTokenId2
                  ],
                  expectedTokenType
                ),
                "PrivateExchanger: Found wrong type in passed collection"
            )

            await expectRevert(
                exchanger.connect(BUYER_SIGNER).chargeBatch(
                  [
                      notExpectedChargedTokenId,
                  ],
                  notExpectedTokenType
                ),
                "PrivateExchanger: Token type not resolved"
            )

            await expectRevert(
              exchanger.connect(BUYER_SIGNER).charge(notExpectedChargedTokenId),
              "PrivateExchanger: Token type not resolved"
            )

            // charge 1st token
            await exchanger.connect(BUYER_SIGNER).chargeBatch(
              [
                  expectedChargedTokenId,
              ],
              expectedTokenType
            )

            await expectRevert(
                exchanger.connect(BUYER_SIGNER).chargeBatch(
                    [
                        expectedChargedTokenId,
                    ],
                    expectedTokenType
                ),
                "PrivateExchanger: Found charged"
            )

            await expectRevert(
                exchanger.connect(BUYER_SIGNER).charge(expectedChargedTokenId),
                "PrivateExchanger: Charged"
            )

        });
    })
});
