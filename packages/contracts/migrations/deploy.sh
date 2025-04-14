#!/bin/bash

# load env variables
source .env

# Deploy001_Diamond (deploys Diamond related contracts)
forge script migrations/Deploy001.s.sol:Deploy001 --rpc-url $RPC_URL --broadcast -vvvv