import { expect } from "chai";
import { network, ethers } from "hardhat";
import { loadFixture, time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { IERC20, MultiplicativePriceFeed, Streamer } from "../typechain-types";

describe("Streamer with MultiplicativePriceFeed", function () {
    const WBTCAddress = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        WBTC_ORACLE = "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c",
        AAVE_ETH_ORACLE = "0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012",
        ETH_USD_ORACLE = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
    const streamingAmount = ethers.parseUnits("1", 18);
    const slippage = 1e5;
    const claimCooldown = time.duration.days(7);
    const sweepCooldown = time.duration.days(10);
    const streamDuration = time.duration.days(90);
    let WBTC: IERC20;
    let WBTC_HOLDER: HardhatEthersSigner;
    let Aave_MultiplicativeOracle: MultiplicativePriceFeed;

    before(async () => {
        WBTC = await ethers.getContractAt("IERC20", WBTCAddress);
        WBTC_HOLDER = await ethers.getImpersonatedSigner("0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8");
        await network.provider.request({
            method: "hardhat_setBalance",
            params: ["0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8", "0x100000000000000000"]
        });
        Aave_MultiplicativeOracle = await (
            await ethers.getContractFactory("MultiplicativePriceFeed")
        ).deploy(AAVE_ETH_ORACLE, ETH_USD_ORACLE, 12, "ETH / USD Multiplicative");
    });

    const fixture = async () => {
        const { user, streamer, streamCreator, returnAddress, signers } = await deployStreamer();
        await initStreamer(streamer, streamingAmount, streamCreator);
        return { user, streamer, streamCreator, returnAddress, signers };
    };

    const deployStreamer = async () => {
        const [user, streamCreator, returnAddress, ...signers] = await ethers.getSigners();
        const streamerFactory = await ethers.getContractFactory("Streamer");
        const streamer = await streamerFactory.deploy(
            WBTCAddress,
            WBTC_ORACLE,
            Aave_MultiplicativeOracle,
            returnAddress,
            streamCreator,
            user,
            8,
            18,
            streamingAmount,
            slippage,
            claimCooldown,
            sweepCooldown,
            streamDuration
        );
        await streamer.waitForDeployment();
        return { streamer, user, streamCreator, returnAddress, signers };
    };

    const initStreamer = async (streamer: Streamer, nativeAssetAmount: bigint, sender: HardhatEthersSigner) => {
        const streamingAssetAmount = await streamer.calculateStreamingAssetAmount(
            nativeAssetAmount + ethers.parseEther("0.000001")
        );
        await WBTC.connect(WBTC_HOLDER).transfer(streamer, streamingAssetAmount);
        await streamer.connect(sender).initialize();
    };

    const getExpectedAmount = async (streamer: Streamer) => {
        const latestTimestamp = (await time.latest()) + 1;
        const startTimestamp = await streamer.startTimestamp();
        let owed =
            latestTimestamp < startTimestamp + BigInt(streamDuration)
                ? (streamingAmount * (BigInt(latestTimestamp) - startTimestamp)) / BigInt(streamDuration)
                : streamingAmount;
        owed -= await streamer.nativeAssetSuppliedAmount();
        const expectedAmount = await streamer.calculateStreamingAssetAmount(owed);
        return expectedAmount;
    };

    const restore = async () => await loadFixture(fixture);

    it("Should claim", async () => {
        const { streamer, user } = await restore();
        await time.increase(time.duration.days(10));
        const expectedAmount = await getExpectedAmount(streamer);
        const tx = await streamer.connect(user).claim();
        await expect(tx).changeTokenBalance(WBTC, user, expectedAmount);
    });

    it("Check returned prices", async () => {
        const { streamer } = await restore();
        const streamingAssetAmount = await streamer.calculateStreamingAssetAmount(ethers.parseEther("1"));
        console.log("Streaming asset amount: ", streamingAssetAmount);
        console.log("Native asset amount: ", await streamer.calculateNativeAssetAmount(streamingAssetAmount));
    });
});
