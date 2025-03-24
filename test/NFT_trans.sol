// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFT.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract NFTTransferTest is Test {
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
        
        // 给用户一些以太币用于铸造和交易
        vm.deal(user, 1 ether);
    }
    
    function testTransferWithFee() public {
        // 用户铸造NFT
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        uint256 tokenId = nft.mint{value: 0.001 ether}("ipfs://test1");
        
        // 记录初始余额
        uint256 initialOwnerBalance = owner.balance;
        address recipient = address(0x3);
        
        // 设置交易价格和计算预期手续费
        uint256 price = 0.1 ether;
        uint256 expectedFee = (price * nft.transactionFeePercent()) / 100; // 1%的手续费
        
        // 执行带手续费的转账
        nft.transferWithFee{value: expectedFee}(recipient, tokenId, price);
        
        // 验证NFT已经转移
        assertEq(nft.ownerOf(tokenId), recipient, "NFT should be transferred to recipient");
        
        // 验证手续费已支付给合约拥有者
        assertEq(owner.balance, initialOwnerBalance + expectedFee, "Fee should be paid to owner");
        
        vm.stopPrank();
    }
    
    function testTransferWithFeeInsufficientFee() public {
        // 用户铸造NFT
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        uint256 tokenId = nft.mint{value: 0.001 ether}("ipfs://test1");
        
        // 设置交易价格和计算预期手续费
        uint256 price = 0.1 ether;
        uint256 expectedFee = (price * nft.transactionFeePercent()) / 100; // 1%的手续费
        uint256 insufficientFee = expectedFee - 0.0001 ether; // 不足的手续费
        
        // 执行带手续费的转账，应该失败
        vm.expectRevert("Insufficient fee");
        nft.transferWithFee{value: insufficientFee}(address(0x3), tokenId, price);
        
        vm.stopPrank();
    }
    
    function testTransferWithFeeNotOwner() public {
        // 用户铸造NFT
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        uint256 tokenId = nft.mint{value: 0.001 ether}("ipfs://test1");
        vm.stopPrank();
        
        // 非所有者尝试转移NFT
        vm.startPrank(owner);
        uint256 price = 0.1 ether;
        uint256 fee = (price * nft.transactionFeePercent()) / 100;
        
        // 应该失败，因为调用者不是NFT所有者
        vm.expectRevert("Not the owner of this NFT");
        nft.transferWithFee{value: fee}(address(0x3), tokenId, price);
        
        vm.stopPrank();
    }
    
    function testTransferWithFeeRefund() public {
        // 用户铸造NFT
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        uint256 tokenId = nft.mint{value: 0.001 ether}("ipfs://test1");
        
        // 记录初始余额
        uint256 initialOwnerBalance = owner.balance;
        uint256 initialUserBalance = user.balance;
        address recipient = address(0x3);
        
        // 设置交易价格和计算预期手续费
        uint256 price = 0.1 ether;
        uint256 expectedFee = (price * nft.transactionFeePercent()) / 100; // 1%的手续费
        uint256 excessPayment = expectedFee + 0.01 ether; // 多付的费用
        
        // 执行带手续费的转账，支付超额费用
        nft.transferWithFee{value: excessPayment}(recipient, tokenId, price);
        
        // 验证NFT已经转移
        assertEq(nft.ownerOf(tokenId), recipient, "NFT should be transferred to recipient");
        
        // 验证手续费已支付给合约拥有者
        assertEq(owner.balance, initialOwnerBalance + expectedFee, "Fee should be paid to owner");
        
        // 验证多余的费用已退还
        assertEq(user.balance, initialUserBalance - expectedFee, "Excess fee should be refunded");
        
        vm.stopPrank();
    }
    
    // 移除 testSetTransactionFeePercent 函数，因为合约中没有 setTransactionFeePercent 方法
}