// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFT.sol";

contract MahjongNFTTest is Test {
    MahjongNFT public nft;
    address public owner;
    address public user;
    
    // 测试前的设置
    function setUp() public {
        owner = address(this);
        user = address(0x1);
        nft = new MahjongNFT();
        
        // 给测试用户一些 ETH
        vm.deal(user, 10 ether);
    }
    
    // 测试铸造功能
    function testMint() public {
        string memory tokenURI = "ipfs://QmExample";
        uint256 mintValue = 0.001 ether;
        
        // 切换到用户身份
        vm.startPrank(user);
        
        // 测试铸造 NFT
        uint256 tokenId = nft.mint{value: mintValue}(tokenURI);
        
        // 验证铸造结果
        assertEq(tokenId, 1, "Token ID should be 1");
        assertEq(nft.ownerOf(tokenId), user, "User should be the owner of the token");
        assertEq(nft.tokenURI(tokenId), tokenURI, "Token URI should match");
        
        vm.stopPrank();
    }
    
    // 测试铸造价格不足的情况
    function testMintInsufficientFunds() public {
        string memory tokenURI = "ipfs://QmExample";
        uint256 insufficientValue = 0.0005 ether; // 低于要求的价格
        
        vm.startPrank(user);
        
        // 预期会失败，因为资金不足
        vm.expectRevert("Insufficient funds");
        nft.mint{value: insufficientValue}(tokenURI);
        
        vm.stopPrank();
    }
    
    // 测试铸造上限
    function testMintMaxSupply() public {
        string memory tokenURI = "ipfs://QmExample";
        uint256 mintValue = 0.001 ether;
        
        vm.startPrank(user);
        
        // 铸造到达上限
        uint256 maxSupply = nft.maxSupply();
        for (uint256 i = 0; i < maxSupply; i++) {
            nft.mint{value: mintValue}(tokenURI);
        }
        
        // 预期下一次铸造会失败，因为已达到上限
        vm.expectRevert("Max supply reached");
        nft.mint{value: mintValue}(tokenURI);
        
        vm.stopPrank();
    }
    
    // 测试 tokenURI 函数
    function testTokenURI() public {
        string memory tokenURI = "ipfs://QmExample";
        uint256 mintValue = 0.001 ether;
        
        vm.startPrank(user);
        uint256 tokenId = nft.mint{value: mintValue}(tokenURI);
        vm.stopPrank();
        
        assertEq(nft.tokenURI(tokenId), tokenURI, "Token URI should match");
    }
    
    // 测试不存在的 tokenId
    function testNonExistentTokenURI() public {
        // 修改为使用正确的错误格式
        vm.expectRevert(abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 999));
        nft.tokenURI(999);
    }
}