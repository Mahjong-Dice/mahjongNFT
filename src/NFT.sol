// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MahjongNFT is
    ERC721,
    ERC721URIStorage,
    Ownable,
    ERC721Enumerable,
    ReentrancyGuard
{
    using ECDSA for bytes32;

    uint256 private _tokenIds = 0;
    // 铸造价格
    uint256 public mintPrice = 0.001 ether;
    // 一副麻将总数 136张
    uint256 private mahjongCount = 136;
    // 每个人最多获得的数量 13 张
    uint256 private senderCountLimit = 13;
    // 限制生成的总数 100 * 13
    uint256 private maxSupply = senderCountLimit * 100;
    // 保存该调用者已有的麻将数量
    // 简化数据结构，只存储额外的信息
    struct MahjongObj {
        uint256 id;
    }
    struct Order {
        address contract_;
        uint256[] tokenIds;
        uint256 price;
        uint256 expiry; // 过期时间
    }

    // 记录NFT上架信息
    mapping(bytes32 => bool) public orderStatus;

    // 新增地址铸造次数跟踪
    mapping(address => uint256) public addressMintCount;
    // 新增手续费比例（1%）
    uint256 public transactionFeePercent = 1;

    /* Events */
    event NFTMinted(
        address indexed minter,
        uint256 indexed tokenId,
        string tokenURI
    );

    event NFTListed(
        address indexed seller,
        address indexed nftContract,
        uint256[] tokenIds,
        uint256 price,
        uint256 expiry
    );

    /* Errors */
    error Expired();

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
        // approve(msg.sender, newItemId); // 新增授权逻辑
        _setTokenURI(newItemId, _tokenURI);

        emit NFTMinted(msg.sender, newItemId, _tokenURI);
        return newItemId;
    }

    // 获取用户所有CID的方法
    function getOwnedCIDs(address owner) public view returns (string[] memory) {
        uint256 balance = balanceOf(owner);
        string[] memory cids = new string[](balance); // 初始化CID数组

        for (uint256 i = 0; i < balance; i++) {
            // 遍历用户的所有NFT
            uint256 tokenId = tokenOfOwnerByIndex(owner, i); // 获取用户的NFT ID
            // require(_exists(tokenId), "Invalid token ID"); // 确保NFT存在
            cids[i] = tokenURI(tokenId);
        }
        return cids;
    }

    // 上架NFT
    function listNFT(
        address contract_,
        uint256[] calldata tokenIds,
        uint256 price,
        uint256 expiry,
        bytes calldata signature
    ) external {
        // if (expiry < block.timestamp) {
        //     revert Expired();
        // }
        require(expiry > block.timestamp, "Expired");
        require(tokenIds.length <= 50, "Max 50 NFTs per batch");

        // 1. 验证签名并获取签名者
        Order memory order = Order(contract_, tokenIds, price, expiry);
        bytes32 orderHash = getOrderHash(order);

        address signer = getSignerOfHash(orderHash, signature);

        // 2. 检查所有token的所有权
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(contract_).ownerOf(tokenIds[i]) == signer,
                "Not token owner"
            );
        }

        // 3. 优化授权检查逻辑
        bool isApprovedForAll = IERC721(contract_).isApprovedForAll(
            signer,
            address(this)
        );
        if (!isApprovedForAll) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(
                    IERC721(contract_).getApproved(tokenIds[i]) ==
                        address(this),
                    "Not approved"
                );
            }
        }

        // 4. 记录订单状态
        require(!orderStatus[orderHash], "Order already exists");
        orderStatus[orderHash] = true;

        // 5. 触发事件（保持原逻辑）
        emit NFTListed(signer, contract_, tokenIds, price, expiry);
    }

    function getSignerOfHash(
        bytes32 _hash,
        bytes calldata signature
    ) public pure returns (address) {
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(_hash);
        address signer = ECDSA.recover(message, signature);
        return signer;
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
    )
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    // 新增设置铸造价格函数（仅owner）
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    // 重写转账函数添加手续费
    function transferWithFee(address to, uint256 tokenId) public {
        uint256 fee = (tx.gasprice * transactionFeePercent) / 100;
        (bool feeSent, ) = owner().call{value: fee}("");
        require(feeSent, "Fee transfer failed");

        safeTransferFrom(msg.sender, to, tokenId);
    }

    // 新增提取合约余额函数
    function withdraw() external onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    function getOrderHash(Order memory order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.contract_,
                    order.tokenIds,
                    order.price,
                    order.expiry
                )
            );
    }
}
