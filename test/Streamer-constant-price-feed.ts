import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture, time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { IComptrollerV2, IERC20, Streamer } from "../typechain-types";

const DUST = 30;

describe("[skip-on-coverage]Streamer", function () {
    const timelockAddress = "0x6d903f6003cca6255D85CcA4D3B5E5146dC33925";
    const comptrollerV2Address = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";
    const CompAddress = "0xc00e94Cb662C3520282E6f5717214004A7f26888";

    const COMP_ORACLE = "0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5",
        CONSTANT_PRICE_FEED = "0xD72ac1bCE9177CFe7aEb5d0516a38c88a64cE0AB";
    const returnAddress = comptrollerV2Address;
    const streamCreator = timelockAddress;
    const streamingAmount = ethers.parseUnits("2000000", 6);
    const slippage = 5e5;
    const claimCooldown = time.duration.days(7);
    const sweepCooldown = time.duration.days(10);
    const streamDuration = time.duration.years(1);
    const minimumNoticePeriod = time.duration.days(30);
    let timelockSigner: HardhatEthersSigner;
    let comptrollerV2: IComptrollerV2;
    let COMP: IERC20;

    before(async () => {
        comptrollerV2 = await ethers.getContractAt("IComptrollerV2", comptrollerV2Address);
        COMP = await ethers.getContractAt("IERC20", CompAddress);
        timelockSigner = await ethers.getImpersonatedSigner(timelockAddress);
    });

    const fixture = async () => {
        const { user, streamer, signers } = await deployStreamer();
        await initStreamer(streamer, streamingAmount, timelockSigner);
        return { user, streamer, signers };
    };

    const deployStreamer = async () => {
        const [user, ...signers] = await ethers.getSigners();
        const streamerFactory = await ethers.getContractFactory("Streamer");
        const streamer = await streamerFactory.deploy(
            CompAddress,
            COMP_ORACLE,
            CONSTANT_PRICE_FEED,
            returnAddress,
            streamCreator,
            user,
            18,
            6,
            streamingAmount,
            slippage,
            claimCooldown,
            sweepCooldown,
            streamDuration,
            minimumNoticePeriod
        );
        await streamer.waitForDeployment();
        return { streamer, user, signers };
    };

    const initStreamer = async (streamer: Streamer, nativeAssetAmount: bigint, sender: HardhatEthersSigner) => {
        const streamingAssetAmount = await streamer.calculateStreamingAssetAmount(nativeAssetAmount + 1n);
        await comptrollerV2.connect(timelockSigner)._grantComp(streamer, streamingAssetAmount);
        await streamer.connect(sender).initialize();
    };

    const getExpectedAmount = async (streamer: Streamer, claimTimestamp: number) => {
        const startTimestamp = await streamer.startTimestamp();
        let owed =
            claimTimestamp < startTimestamp + BigInt(streamDuration)
                ? (streamingAmount * (BigInt(claimTimestamp) - startTimestamp)) / BigInt(streamDuration)
                : streamingAmount;
        owed -= await streamer.nativeAssetSuppliedAmount();
        const expectedAmount = await streamer.calculateStreamingAssetAmount(owed);
        return expectedAmount;
    };

    const restore = async () => await loadFixture(fixture);

    it("Should calculate the price correctly using constant price feed", async () => {
        const { streamer, user } = await restore();
        const usdAmount = ethers.parseUnits("1000", 6); // 1000 USD
        const compAmount = await streamer.calculateStreamingAssetAmount(usdAmount);
        expect(await streamer.calculateNativeAssetAmount(compAmount)).to.be.closeTo(usdAmount, DUST);
        await time.increase(time.duration.days(60));
        const expectedAmount = await getExpectedAmount(streamer, (await time.latest()) + 1);
        const tx = await streamer.connect(user).claim();
        await expect(tx).changeTokenBalance(COMP, user, expectedAmount);
    });
});
