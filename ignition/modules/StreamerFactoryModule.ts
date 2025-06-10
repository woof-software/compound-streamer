import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StreamerFactoryModule = buildModule("StreamerFactory", (m) => {
    const factory = m.contract("StreamerFactory");

    return { factory };
});

export default StreamerFactoryModule;
