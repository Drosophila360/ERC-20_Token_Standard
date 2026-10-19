-include .env

.PHONY: remove install anvil deploy-manual deploy-ourtoken deploy-manual-zk deploy-ourtoken-zk deploy-manual-sepolia deploy-ourtoken-sepolia deploy-manual-zk-sepolia deploy-ourtoken-zk-sepolia

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_ZKSYNC_LOCAL_KEY := 0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110
ACCOUNT ?= devAccount

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops && forge install foundry-rs/forge-std  && forge install openzeppelin/openzeppelin-contracts

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy-manual:
	@forge script script/DeployManualToken.s.sol:DeployManualToken \
	--rpc-url http://localhost:8545 \
	--private-key $(DEFAULT_ANVIL_KEY) \
	--broadcast \
	-vvvv

deploy-ourtoken:
	@forge script script/DeployOurToken.s.sol:DeployOurToken \
	--rpc-url http://localhost:8545 \
	--private-key $(DEFAULT_ANVIL_KEY) \
	--broadcast \
	-vvvv

deploy-manual-zk:
	@forge script script/DeployManualToken.s.sol:DeployManualToken \
	--rpc-url http://127.0.0.1:8011 \
	--private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) \
	--legacy \
	--zksync \
	-vvvv	

deploy-ourtoken-zk:
	@forge script script/DeployOurToken.s.sol:DeployOurToken \
	--rpc-url http://127.0.0.1:8011 \
	--private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) \
	--legacy \
	--zksync \
	-vvvv

deploy-manual-sepolia:
	@forge script script/DeployManualToken.s.sol:DeployManualToken \
	--rpc-url $(SEPOLIA_RPC_URL) \
	--account $(ACCOUNT) \
	--broadcast \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	-vvvv

deploy-ourtoken-sepolia:
	@forge script script/DeployOurToken.s.sol:DeployOurToken \
	--rpc-url $(SEPOLIA_RPC_URL) \
	--account $(ACCOUNT) \
	--broadcast \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	-vvvv

deploy-manual-zk-sepolia:
	@forge script script/DeployManualToken.s.sol:DeployManualToken \
	--rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) \
	--account $(ACCOUNT) \
	--legacy \
	--zksync \
	-vvvv


deploy-ourtoken-zk-sepolia:
	@forge script script/DeployOurToken.s.sol:DeployOurToken \
	--rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) \
	--account $(ACCOUNT) \
	--legacy \
	--zksync \
	-vvvv
