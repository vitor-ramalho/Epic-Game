const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
    const gameContract = await gameContractFactory.deploy(
        ["Like a Boss", "Forever Alone", "LOL"],       // Names
        ["https://i.pinimg.com/564x/dd/55/01/dd5501c3805291af0c55bf5c659b4df6.jpg", // Images
            "https://i.pinimg.com/564x/ef/8f/0d/ef8f0d5972871f40da48b91812f7ecd9.jpg",
            "https://i.pinimg.com/564x/db/3f/a3/db3fa3587c861a8ac8a9175849ef78b1.jpg"],
        [300, 50, 130],                    // HP values
        [120, 50, 100],                       // Attack damage values
        "Troll Face", // Boss name
        "https://i.imgur.com/1b6XRcm.png", // Boss image
        10000, // Boss hp
        50 // Boss attack damage
    );
    await gameContract.deployed();
    console.log("Contract deployed to:", gameContract.address);

    let txn;
    txn = await gameContract.mintCharacterNFT(0);
    await txn.wait();
    console.log("Minted NFT #1");
  
    txn = await gameContract.mintCharacterNFT(1);
    await txn.wait();
    console.log("Minted NFT #2");
  
    txn = await gameContract.mintCharacterNFT(2);
    await txn.wait();
    console.log("Minted NFT #3");
  
    console.log("Done deploying and minting!");
}
const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();