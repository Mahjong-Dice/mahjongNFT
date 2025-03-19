```sh
# 启动 anvil
anvil --state ./anvil_state.json

# 给浏览器钱包 发钱
cast send \
--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x5098011a8943878e658B1168fea40786b1447F26 \
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
# source .env
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

# 4. test
cast send 0x4A679253410272dd5232B3Ff7cF5dbB88f295319 "listNFT(address,uint256[],uint256,uint256,bytes)" "0x4A679253410272dd5232B3Ff7cF5dbB88f295319" "[1]" "10000000000000000" "1742355029" "0xb81e6ccfed0dfaa9c6e8809e60f06f4427f89bc0c76544e93a364b0741c674933e9579f660676beeffde9078afeb974f4d8028bdc7d7927bc9805c552098e77a1c" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545

```
* cast send：用于状态修改操作（需要gas费）
* cast call：用于只读操作（无状态修改）