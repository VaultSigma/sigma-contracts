# Sigma Contracts

A monorepo containing smart contracts and related tooling for the Sigma protocol.

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

### Building

```bash
yarn build
```

### Testing

```bash
yarn test
```

### Deployment

```bash
yarn deploy
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