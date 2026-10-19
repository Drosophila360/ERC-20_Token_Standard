
# ERC-20_Token_Standard with Foundry

[![Solidity](https://img.shields.io/badge/Solidity-smart%20contracts-363636?logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/toolchain-Foundry-orange)](https://book.getfoundry.sh/)

A Foundry project exploring Ethereum's ERC-20 token standard by contrasting a low-level implementation written from scratch with a contract built on OpenZeppelin. The goal is to demonstrate token ledger management, transfers, approvals, inheritance, and common development workflows. This repository is educational; review and audit contracts before production use.

## Architecture & Contract Logic

### `ManualToken.sol`

`ManualToken` demonstrates core ERC-20 behavior without external libraries. Its ledger is maintained with mappings such as:

- `mapping(address => uint256) balances` associates each account with its token balance.
- `mapping(address => mapping(address => uint256)) allowances` tracks how much an owner permits each spender to transfer.

The main operations are:

- **`transfer(to, amount)`** checks the caller's balance, debits the sender, credits the recipient, and emits `Transfer`.
- **`approve(spender, amount)`** sets the caller's allowance for a spender and emits `Approval`.
- **`transferFrom(from, to, amount)`** checks the owner's balance and the caller's allowance, consumes the allowance, moves the tokens, and emits the relevant events.

The implementation must also reject invalid addresses and insufficient balances or allowances, and maintain safe arithmetic. Consult the contract and tests for the exact API and behavior.

### `OurToken.sol`

`OurToken` builds on `ERC20.sol` from `@openzeppelin/contracts`. OpenZeppelin provides a widely used implementation of standard ERC-20 accounting, transfers, allowances, and events, allowing the contract to focus on configuration and token-specific behavior. It demonstrates inheritance and constructor-time minting. Check the source for the configured name, symbol, initial supply, and mint recipient.

## Prerequisites & Installation

Install Foundry (`forge`, `cast`, and `anvil`) using the official installer, then install or update the tools:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

For ZKsync Era development, install the ZKsync-enabled Foundry toolchain using the [foundry-zksync documentation](https://github.com/matter-labs/foundry-zksync):

```bash
foundryup-zksync
```

Install Node.js and Docker for local ZKsync node testing. Start the development node; the CLI may prompt to configure or run its Docker image:

```bash
npx zksync-cli dev start
```

Keep the node running in a separate terminal. The repository's Makefile may provide shortcuts; inspect `make help` or the `Makefile` for available targets and required configuration.


### Clone and Set Up the Repository

```bash
git clone https://github.com/Drosophila360/ERC-20_Token_Standard.git
git checkout main
cd ERC-20_Token_Standard
forge install
```

## Environment Configuration

Configure RPC endpoints and explorer API keys using the variable names expected by project scripts and the Makefile. For example, create a local `.env`:

```dotenv
SEPOLIA_RPC_URL="YOUR_ALCHEMY_MAINNET_SEPOLIA_RPC_ENDPOINT"
ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_API_KEY>
ZKSYNC_SEPOLIA_RPC_URL="YOUR_ALCHEMY_ZKSYNC_SEPOLIA_RPC_ENDPOINT"
```

Load the values in your shell or use the project's environment-loading workflow. Do not store private keys in `.env`, source control, shell history, or deployment scripts. Instead, import a deployer into Foundry's encrypted keystore:

```bash
cast wallet import devAccount --interactive
```

Use a strong keystore password and keep backups secure. Never commit private keys, keystore files, passwords, or API credentials.

## Compilation & Local Testing

Compile contracts and run tests :

### compile contracts

```bash
forge build
```

### Run Tests

```bash
forge test
```

For a filtered test run:
1. By path;

```bash
forge test --mp test/*.t.sol
```
2. By name;
```bash
forge test --mt <testName>
```

Tests should exercise balance updates, transfers, insufficient-balance failures, approvals, allowance consumption, and events. Use Makefile targets if they configure project-specific compiler settings or wrap these commands.

## Deployment Guide


### Local EVM / Anvil

To streamline deployments, this project uses a Makefile for workflow automation. Below are the underlying raw Foundry CLI commands used for each network, alongside their automated make equivalents.

Start a local EVM node in one terminal:

```bash
anvil
```

Deploy in another terminal using an Anvil-only test key; never use a real wallet key for local testing:

Under The Hood:
```bash
	@forge script script/DeployManualToken.s.sol:DeployManualToken \
	--rpc-url http://localhost:8545 \
	--private-key $(DEFAULT_ANVIL_KEY) \
	--broadcast \
	-vvvv
```

Automated shortcut:
```bash
make deploy-manual
```

### Local ZKsync Era

Start the local node with `npx zksync-cli dev start` and confirm its RPC is available on port `8011`. Use the ZKsync Foundry toolchain and any backend-specific options required by the installed version:

Under The Hood:
```bash
@forge script script/DeployManualToken.s.sol:DeployManualToken \
	--rpc-url http://127.0.0.1:8011 \
	--private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) \
	--legacy \
	--zksync \
	-vvvv
```	
Automated shortcut:
```bash
make deploy-manual-zk
```

ZKsync compilation and deployment can require options that differ from standard EVM Foundry workflows. Follow the installed `foundry-zksync` documentation and the project's Makefile.

### Sepolia Testnet

Set `SEPOLIA_RPC_URL`, import the deployer into the encrypted keystore, and broadcast. Adjust the gas price override to current network conditions; the value below is only an example.

Under The Hood:
```bash
	@forge script script/DeployManualToken.s.sol:DeployManualToken \
	--rpc-url $(SEPOLIA_RPC_URL) \
	--account $(ACCOUNT) \
	--broadcast \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	--gas-limit 5000000 \
	-vvvv
```

Automated shortcut:
```bash
make deploy-manual-sepolia
```

Foundry prompts for the encrypted keystore password when required. Check `forge script --help` for account and keystore options supported by your version. Do not pass a real private key on the command line.

## Security & Best Practices

- Never commit private keys, keystore passwords, `.env` files, or API credentials.
- Ensure `broadcast/` is ignored by Git; inspect deployment artifacts and logs before sharing them.
- Use isolated test accounts on Anvil and testnets. Verify the chain, RPC, deployer, constructor parameters, and gas settings before broadcasting.
- Treat `ManualToken` as educational until thoroughly reviewed. Prefer established libraries such as OpenZeppelin for production contracts, and arrange an independent security review before production deployment.

## License & Credits

This project is distributed under an open-source license defined in the repository. Please refer to the repository's `LICENSE` file for exact terms.

Credits:

- Foundry: smart contract development and testing workflow
- OpenZeppelin: contract safety patterns and reusable standards
- CyfrinUpdraft: learning roadmap and guide

