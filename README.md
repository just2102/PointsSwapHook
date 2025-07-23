# PointsSwapHook - Uniswap V4 Hook

A Uniswap V4 hook that implements a points-based rewards system for ETH=>Token swaps.

## Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation

```shell
# Clone the repository
git clone https://github.com/just2102/PointsSwapHook.git

# Install dependencies
forge install

# Build the project
forge build
```

## Deployment

### Method 1: Using Environment Variables (Recommended)

1. **Create a `.env` file** in the project root:

```env
# Required: Pool Manager address for your target network
POOL_MANAGER=0x1F98400000000000000000000000000000000004

# Required: Your private key for deployment
DEPLOYER_PRIVATE_KEY=0x1234567890abcdef...

# Required: RPC URL for your target network
RPC_URL=https://0xrpc.io/uni
```

2. **Load environment variables:**

```shell
source .env
```

3. **Deploy the hook:**

```shell
forge script script/Deploy.s.sol \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --broadcast \
    --verify
```

### Method 2: Using Function Parameters

Deploy with a specific Pool Manager address:

```shell
forge script script/Deploy.s.sol \
    --rpc-url <your_rpc_url> \
    --private-key <your_private_key> \
    --broadcast
```

## Network Configurations

### Unichain Sepolia (Default)

```env
POOL_MANAGER=0x1F98400000000000000000000000000000000004
RPC_URL=https://sepolia.unichain.org
```

### Arbitrum

```env
POOL_MANAGER=0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32
RPC_URL=https://arb1.arbitrum.io/rpc
```

### Local Development

```env
POOL_MANAGER=0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
RPC_URL=http://localhost:8545
```

## Testing

Run the test suite:

```shell
forge test
```

Run with gas reporting:

```shell
forge test --gas-report
```

## Development

### Format Code

```shell
forge fmt
```

### Generate Gas Snapshots

```shell
forge snapshot
```

### Start Local Node

```shell
anvil
```

## Hook Details

This hook implements:

- **Before Swap**: Pre-swap logic and validations
- **After Swap**: Points calculation and distribution

### Hook Flags

- `BEFORE_SWAP_FLAG`: Enabled
- `AFTER_SWAP_FLAG`: Enabled

## Security Notes

⚠️ **Important**:

- Never commit your `.env` file to version control
- Always use environment variables for sensitive data like private keys
- The CREATE2 deployer address `0x4e59b44847b379578588920cA78FbF26c0B4956C` must exist on your target network

## Troubleshooting

### Common Issues

1. **"missing CREATE2 deployer" error**: The CREATE2 deployer contract doesn't exist on your network. This is common on local networks.

2. **Gas estimation failed**: Increase gas limit in your `.env` file or use `--gas-limit` flag.

3. **Nonce too low/high**: Your account nonce is out of sync. Try using `--slow` flag or check your account state.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request
