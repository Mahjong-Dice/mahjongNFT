// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract MahjongNFT is ERC721, ERC721URIStorage, Ownable, ERC721Enumerable, ReentrancyGuard {
    uint256 private _tokenIds;
    // 铸造价格
    uint256 public mintPrice = 0.001 ether;
    // 一副麻将总数 136张
    uint256 public mahjongCount = 136;
    // 每个人最多获得的数量 13 张
    uint256 public senderCountLimit = 13;
    // 限制生成的总数 100 * 13
    uint256 public maxSupply = senderCountLimit * 100;
    // 保存该调用者已有的麻将数量
    // 简化数据结构，只存储额外的信息
    struct MahjongObj {
        uint256 id;
        // 这里可以添加其他你需要的麻将特定属性
        // 例如：麻将类型、创建时间等
    }
    // 新增地址铸造次数跟踪
    mapping(address => uint256) public addressMintCount;
    // 新增手续费比例（1%）
    uint256 public transactionFeePercent = 1;
    // 保存所有麻将信息
    mapping(uint256 => MahjongObj) private mahjongs;

    constructor() ERC721("MahjongNFT", "MJNFT") Ownable(msg.sender) {}

    // 实现mint函数
    function mint(string memory _tokenURI) public payable returns (uint256) {
        // 验证铸造数量限制
        require(
            addressMintCount[msg.sender] < senderCountLimit,
            "Exceed individual limit"
        ); // 验证铸造数量限制
        require(msg.value >= mintPrice, "Insufficient funds"); // 验证支付金额
        require(_tokenIds < maxSupply, "Max supply reached"); // 验证总供应量

        // 状态更新
        _tokenIds++;
        uint256 newItemId = _tokenIds;
        // 更新铸造次数
        addressMintCount[msg.sender]++;

        // 处理支付
        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Payment failed");

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        mahjongs[newItemId] = MahjongObj({id: newItemId});

        return newItemId;
    }

    // 获取用户所有CID的方法
    function getOwnedCIDs(address owner) public view returns (string[] memory) {
        uint256 balance = balanceOf(owner);
        string[] memory cids = new string[](balance); // 初始化CID数组

        for (uint256 i = 0; i < balance; i++) {
            // 遍历用户的所有NFT
            uint256 tokenId = tokenOfOwnerByIndex(owner, i); // 获取用户的NFT ID
            require(_exists(tokenId), "Invalid token ID"); // 确保NFT存在
            cids[i] = tokenURI(tokenId);
        }
        return cids;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    // 重写ERC721URIStorage的函数，用于获取CID
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 新增设置铸造价格函数（仅owner）
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    // 重写转账函数添加手续费
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // 计算手续费
        uint256 fee = (tx.gasprice * transactionFeePercent) / 100;

        // 转账手续费给合约所有者
        (bool feeSent, ) = owner().call{value: fee}("");
        require(feeSent, "Fee transfer failed");

        super._transfer(from, to, tokenId);
    }

    // 新增提取合约余额函数
    function withdraw() external onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }
}
