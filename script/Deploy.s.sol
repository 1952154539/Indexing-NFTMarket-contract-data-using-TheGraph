// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/BaseERC20.sol";
import "../src/NFTMarket.sol";
import "../src/SimpleNFT.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy BaseERC20 token with 1 million initial supply (18 decimals)
        BaseERC20 token = new BaseERC20("Market Token", "MTK", 1_000_000 * 10**18);
        console.log("BaseERC20 deployed at:", address(token));

        // Deploy SimpleNFT
        SimpleNFT simpleNFT = new SimpleNFT();
        console.log("SimpleNFT deployed at:", address(simpleNFT));

        // Deploy NFTMarket with deployer as fee recipient and 2.5% fee
        NFTMarket nftMarket = new NFTMarket(msg.sender, 250);
        console.log("NFTMarket deployed at:", address(nftMarket));

        // Mint an NFT for testing
        simpleNFT.mint(msg.sender, "https://ipfs.io/ipfs/QmTest1");
        console.log("Test NFT minted to:", msg.sender);

        // Approve NFTMarket to transfer NFT
        simpleNFT.setApprovalForAll(address(nftMarket), true);
        console.log("NFTMarket approved for NFT transfers");

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("BaseERC20:", address(token));
        console.log("SimpleNFT:", address(simpleNFT));
        console.log("NFTMarket:", address(nftMarket));
    }
}
