# Sigma Protocol

Sigma is a decentralized protocol that enables users to deposit collateral and earn rewards through a unique time-locked staking mechanism. The protocol features a flexible rebalancing system that optimizes yield generation across different strategies.

## 🌟 Key Features

- **Time-Locked Staking**: Users can lock their collateral for varying durations to earn boosted rewards
- **Multi-Collateral Support**: Support for multiple collateral types with individual risk parameters
- **Dynamic Rebalancing**: Automated rebalancing of assets across different strategies for optimal yield
- **Flexible Reward System**: Quadratic reward model based on lock duration
- **Diamond Pattern**: Modular architecture using the Diamond proxy pattern for upgradeability

## 📊 Protocol Overview

### Core Components

1. **Sigma Pool**
   - Manages collateral deposits and withdrawals
   - Handles time-locked staking
   - Calculates and distributes rewards

2. **Sigma Rebalancer**
   - Executes rebalancing operations
   - Interacts with DEX routers
   - Manages strategy allocations

3. **Strategy Registry**
   - Registers and manages investment strategies
   - Tracks strategy performance
   - Controls strategy parameters

### Reward Mechanism

The protocol implements a quadratic reward model where:
- Base rewards are provided for all stakers
- Additional rewards are calculated based on lock duration
- Rewards are normalized between minimum (1 week) and maximum (1 year) lock periods

## 📝 Contract Deployment Addresses

| Network | Contract | Address | Deployment Date |
|---------|----------|---------|-----------------|
| Swell Testnet | AccessControlFacet | `0x44928be489e885b096b786ecb30ce8fe58e9e99b` | DONE |
| Swell Testnet | DiamondCutFacet | `0xdc1d46bfece33220137f8d2184454560ffe0fb0b` | DONE |
| Swell Testnet | DiamondLoupeFacet | `0x7c865be49049432265be00b063a348d854f6b701` | DONE |
| Swell Testnet | ManagerFacet | `0x8ad9917d2a1da461bce279c0ccfcf6efac6e5f01` | DONE |
| Swell Testnet | OwnershipFacet | `0xb46c91a431fe226ab0954beedf72b4636b0fadc3` | DONE |
| Swell Testnet | SigmaPoolFacet | `0x69e1c2e828ab07cdd7fa113c0361b069377537be` | DONE |
| Swell Testnet | Diamond | `0xa5d627543a5c57005b576b63253cbffcdb473049` | DONE |
| Swell Testnet | vSigmaToken | `0xb4b9a68611ff4ca569edc263b73328b2fa8bac2f` | DONE |

## 🚀 Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or later)
- [Yarn](https://yarnpkg.com/) (v4 or later)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/VaultSigma/sigma-contracts.git
cd sigma-contracts
```

2. Install dependencies:
```bash
yarn install
```

3. Copy the environment file and fill in your values:
```bash
cp .env.example .env
```

4. Fill in your environment variables in `.env`:
- `NETWORK_RPC_URL`: Your Ethereum node RPC URL
- `NETWORK_CHAIN_ID`: The chain ID of the network you're deploying to
- `PRIVATE_KEY`: Your wallet's private key
- `WALLET_ADDRESS`: Your wallet's address
- `INFURA_API_KEY`: Your Infura API key (if using Infura)
- `ETHERSCAN_API_KEY`: Your Etherscan API key (for contract verification)

## 📦 Project Structure

```
packages/
└── contracts/                 # Smart contracts package
    ├── src/                   # Source files
    │   ├── Diamond.sol        # Diamond proxy contract
    │   ├── facets/            # Diamond facets
    │   │   ├── DiamondCutFacet.sol
    │   │   ├── DiamondLoupeFacet.sol
    │   │   └── OwnershipFacet.sol
    │   ├── interfaces/        # Contract interfaces
    │   └── libraries/         # Shared libraries
    ├── test/                  # Test files
    ├── script/                # Deployment scripts
    └── lib/                   # Dependencies
```

## 🛠 Development

### Available Commands

```bash
# Build and Compile
yarn compile        # Compile contracts
yarn build         # Build all packages

# Testing
yarn test     # Run tests with mainnet fork
yarn test:coverage # Run tests with coverage

# Deployment
yarn deploy        # Deploy contracts
yarn verify        # Verify contracts on Etherscan

# Development
yarn chain         # Start local blockchain
yarn fork          # Start mainnet fork
yarn format        # Format code
yarn lint          # Lint code
```

### Testing

The protocol includes comprehensive test suites that can be run in different environments:

1. **Local Testing**
```bash
yarn test
```
This runs all tests in a local environment, which is faster but doesn't include interactions with external protocols.

2. **Mainnet Fork Testing**
```bash
yarn test --fork-url swell
```
The mainnet fork testing environment is crucial for:
- Testing against real-world conditions and contracts
- Interact with existing DeFi protocols and tokens
- Verify protocol behavior with actual market conditions
- Test integrations with external protocols
- Simulate real user interactions and scenarios

To run specific test files or functions:
```bash
# Run a specific test file
yarn test --match-path test/SigmaPool.t.sol

# Run a specific test function
yarn test --match-test testDeposit_ShouldWork

# Run tests with gas reporting
yarn test --gas-report
```

### Deployment

```bash
# Deploy to local network
yarn deploy

# Deploy to testnet
yarn deploy --network goerli

# Deploy and verify on Etherscan
yarn deploy --verify
```

## 🔒 Security

- Never commit your `.env` file
- Keep your private keys secure
- Review all contract changes thoroughly
- Follow best practices for smart contract development

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request 