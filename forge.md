```sh
# 启动 anvil
  --state ./anvil_state.json

# 给浏览器钱包 发钱
cast send \
--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x85B43312775fe284b14CfE0CFdf064bD5007a0C6 \
--value 1000000000000000000 \
--rpc-url http://localhost:8545

# 合约部署到 anvil
forge create \
--rpc-url 127.0.0.1:8545 \
--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
src/NFT.sol:MahjongNFT \
--broadcast

# 部署合约到 以太坊测试网
# .env 配置变量
forge create \
--rpc-url $SEPOLIA_RPC_URL \
--private-key $PRIVATE_KEY \
--etherscan-api-key $ETHERSCAN_API_KEY \
src/NFT.sol:MahjongNFT \
--broadcast \
--verify \
-vvvv

# 测试链交互
cast send 0xFB97302543f1A4ce9B4362E4F9620F62f7264954 \
"increment()" \
--private-key $PRIVATE_KEY \
--rpc-url $SEPOLIA_RPC_URL

# 合约交互
# 1. 设置数值（交易操作）
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
"setNumber(uint256)" 100 \
--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
--rpc-url http://localhost:8545

# 2. 增加数值（交易操作）
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
"increment()" \
--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
--rpc-url http://localhost:8545

# 3. 查询数值（只读操作）
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
"number()(uint256)" \
--rpc-url http://localhost:8545

```
* cast send：用于状态修改操作（需要gas费）
* cast call：用于只读操作（无状态修改）