// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFT.sol";

contract MahjongNFTTest is Test {
    MahjongNFT public nft;
    address public owner;
    address public user;

    // 添加 receive 函数以接收 ETH
    receive() external payable {}
    // 测试前的设置
    function setUp() public {
        owner = address(this);
        user = address(0x1);
        nft = new MahjongNFT();

        // 给测试用户一些 ETH
        vm.deal(user, 10 ether);
        // 给测试合约一些 ETH 以支持接收转账
        vm.deal(owner, 10 ether);
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
        assertEq(
            nft.ownerOf(tokenId),
            user,
            "User should be the owner of the token"
        );
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

        // 创建多个用户地址来测试最大供应量
        for (uint256 i = 0; i < 100; i++) {
            // 100个地址
            address currentUser = address(uint160(i + 1000));
            vm.deal(currentUser, 1 ether); // 给每个用户一些ETH
            vm.startPrank(currentUser);

            // 每个用户铸造13个NFT
            for (uint256 j = 0; j < 13; j++) {
                nft.mint{value: mintValue}(tokenURI);
            }

            vm.stopPrank();
        }

        // 尝试再铸造一个，应该失败
        vm.startPrank(address(2000));
        vm.deal(address(2000), 1 ether);
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
        vm.expectRevert(
            abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 999)
        );
        nft.tokenURI(999);
    }

    function testGetOwnedCIDs() public {
        string memory tokenURI1 = "ipfs://QmExample1";
        string memory tokenURI2 = "ipfs://QmExample2";
        string memory tokenURI3 = "ipfs://QmExample3";
        uint256 mintValue = 0.001 ether;
        vm.startPrank(user);
        // 铸造 3 张 NFT
        nft.mint{value: mintValue}(tokenURI1);
        nft.mint{value: mintValue}(tokenURI2);
        nft.mint{value: mintValue}(tokenURI3);

        // 获取所有id
        string[] memory cids = nft.getOwnedCIDs(user);

        // 验证结果
        assertEq(cids.length, 3, "User should have 3 tokens");

        vm.stopPrank();
    }

    function testSetMintPrice() public {
        uint256 newMintPrice = 0.002 ether;

        // 测试非所有者调用（应该失败）
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        nft.setMintPrice(newMintPrice);
        vm.stopPrank();

        // 测试所有者调用（应该成功）
        vm.startPrank(owner);
        nft.setMintPrice(newMintPrice);
        assertEq(nft.mintPrice(), newMintPrice);
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 initialBalance = owner.balance;
        uint256 mintValue = 0.001 ether;  // 添加铸造所需的 ETH 

        vm.startPrank(user);
        nft.mint{value: mintValue}("ipfs://QmExample");
        vm.stopPrank();

        vm.startPrank(owner);
        nft.withdraw();
        vm.stopPrank();

        // 验证余额是否增加
        assertEq(owner.balance, initialBalance + mintValue);
    }
    
}
