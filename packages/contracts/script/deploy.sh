#!/bin/bash

# load env variables
source .env

# Deploy001_Diamond (deploys Diamond related contracts)
forge script DeployToken.s.sol:DeployScript --rpc-url $RPC_URL --broadcast -vvvv --fork-url