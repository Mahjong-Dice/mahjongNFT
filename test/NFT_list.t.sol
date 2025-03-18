// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFT.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract NFTListingTest is Test {
    using ECDSA for bytes32;
    
    MahjongNFT nft;
    address owner = address(0x1);
    address user = address(0x2);
    uint256 ownerPrivateKey = 0xA11CE;
    uint256 userPrivateKey = 0xB0B;
    
    function setUp() public {
        // 确保私钥和地址正确映射
        owner = vm.addr(ownerPrivateKey);
        user = vm.addr(userPrivateKey);
        
        vm.startPrank(owner);
        nft = new MahjongNFT();
        vm.stopPrank();
        
        // 给用户一些以太币用于铸造
        vm.deal(user, 1 ether);
    }
    
    function testListNFT() public {
        // 用户铸造NFT
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        nft.mint{value: 0.001 ether}("ipfs://test1");
        nft.mint{value: 0.001 ether}("ipfs://test2");
        
        // 准备上架数据
        address contractAddress = address(nft);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        uint256 price = 0.01 ether;
        uint256 expiry = block.timestamp + 1 days;
        
        // 授权市场合约操作NFT
        nft.setApprovalForAll(address(nft), true);
        
        // 创建订单哈希
        MahjongNFT.Order memory order = MahjongNFT.Order(
            contractAddress,
            tokenIds,
            price,
            expiry
        );
        bytes32 orderHash = nft.getOrderHash(order);
        
        // 用户签名 - 使用正确的私钥
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(orderHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, message);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 上架NFT
        nft.listNFT(contractAddress, tokenIds, price, expiry, signature);
        
        // 验证订单状态
        assertTrue(nft.orderStatus(orderHash), "Order should be active");
        vm.stopPrank();
    }
    
    function testListNFTExpired() public {
        // 用户铸造NFT
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        nft.mint{value: 0.001 ether}("ipfs://test1");
        
        // 准备上架数据，但过期时间已过
        address contractAddress = address(nft);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        uint256 price = 0.01 ether;
        uint256 expiry = block.timestamp - 1; // 已过期
        
        // 授权市场合约操作NFT
        nft.setApprovalForAll(address(nft), true);
        
        // 创建订单哈希
        MahjongNFT.Order memory order = MahjongNFT.Order(
            contractAddress,
            tokenIds,
            price,
            expiry
        );
        bytes32 orderHash = nft.getOrderHash(order);
        
        // 用户签名
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(orderHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, message);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 上架NFT应该失败，因为已过期
        vm.expectRevert(MahjongNFT.Expired.selector);
        nft.listNFT(contractAddress, tokenIds, price, expiry, signature);
        vm.stopPrank();
    }
    
    function testListNFTNotOwner() public {
        // 用户铸造NFT
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        nft.mint{value: 0.001 ether}("ipfs://test1");
        vm.stopPrank();
        
        // 准备上架数据
        address contractAddress = address(nft);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        uint256 price = 0.01 ether;
        uint256 expiry = block.timestamp + 1 days;
        
        // 创建订单哈希
        MahjongNFT.Order memory order = MahjongNFT.Order(
            contractAddress,
            tokenIds,
            price,
            expiry
        );
        bytes32 orderHash = nft.getOrderHash(order);
        
        // 所有者签名（而不是用户）
        vm.startPrank(owner);
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(orderHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, message);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 上架NFT应该失败，因为签名者不是NFT所有者
        vm.expectRevert("Not token owner");
        nft.listNFT(contractAddress, tokenIds, price, expiry, signature);
        vm.stopPrank();
    }
    
    function testListNFTNotApproved() public {
        // 用户铸造NFT
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        nft.mint{value: 0.001 ether}("ipfs://test1");
        
        // 准备上架数据
        address contractAddress = address(nft);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        uint256 price = 0.01 ether;
        uint256 expiry = block.timestamp + 1 days;
        
        // 不授权市场合约操作NFT
        
        // 创建订单哈希
        MahjongNFT.Order memory order = MahjongNFT.Order(
            contractAddress,
            tokenIds,
            price,
            expiry
        );
        bytes32 orderHash = nft.getOrderHash(order);
        
        // 用户签名
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(orderHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, message);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 上架NFT应该失败，因为没有授权
        vm.expectRevert("Not approved");
        nft.listNFT(contractAddress, tokenIds, price, expiry, signature);
        vm.stopPrank();
    }
}