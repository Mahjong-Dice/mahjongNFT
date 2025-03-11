// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MahjongNFT is ERC721, ERC721URIStorage, Ownable {
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
    struct MahjongObj {
        uint256 id; // id
        string metadataCID; // IPFS内容标识符
        address owner;
    }
    mapping(uint256 => MahjongObj) private mahjongs;

    constructor() ERC721("MahjongNFT", "MJNFT") Ownable(msg.sender) {}

    // 实现mint函数
    function mint(string memory _tokenURI) public payable returns (uint256) {
        // 1. 验证调用者是否有eth
        require(msg.value >= mintPrice, "Insufficient funds");
        // 2. 达到生成上限
        require(_tokenIds < maxSupply, "Max supply reached");

        _tokenIds++;
        uint256 newItemId = _tokenIds;

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        mahjongs[newItemId] = MahjongObj({
            id: newItemId,
            owner: msg.sender,
            metadataCID: _tokenURI
        });

        return newItemId;
    }

    // 重写必要的函数以解决继承冲突
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
}
