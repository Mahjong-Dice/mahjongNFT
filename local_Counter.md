```sh
# 合约部署到 anvil
forge create \
--rpc-url 127.0.0.1:8545 \
--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
src/Counter.sol:Counter \
--broadcast

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