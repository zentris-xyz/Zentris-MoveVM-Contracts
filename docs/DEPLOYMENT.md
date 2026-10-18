# Zentris — Deployment Guide

## Prerequisites

- Supra CLI installed
- Testnet account with faucet SUPRA
- Git clone of `zentris` repo

## Step 1: Build

```bash
cd zentris
supra move tool build --package-dir .
```

Expected output: compiled bytecode in `build/zentris/bytecode_modules/`.

## Step 2: Test

```bash
supra move tool test --package-dir .
```

Expected: 2 tests pass (deposit/withdraw, unsupported asset rejection).

## Step 3: Publish to Testnet

```bash
supra move tool publish \
  --package-dir . \
  --rpc-url https://rpc-testnet.supra.com \
  --private-key <YOUR_PRIVATE_KEY>
```

After publish, note the module address (e.g. `0xabc...`). This is `@zentris`.

## Step 4: Initialize Registry

```bash
supra move tool run \
  --function-id "0xabc...::registry::init_module" \
  --rpc-url https://rpc-testnet.supra.com \
  --private-key <YOUR_PRIVATE_KEY>
```

> Note: `init_module` is called automatically on publish in most cases. If already initialized, skip this step.

## Step 5: Register SUPRA as First Asset

```bash
supra move tool run \
  --function-id "0xabc...::registry::add_supported_asset" \
  --type-args "0x1::supra_coin::SupraCoin" \
  --args string:SUPRA u8:8 u32:<PAIR_ID> \
  --rpc-url https://rpc-testnet.supra.com \
  --private-key <YOUR_PRIVATE_KEY>
```

Replace `<PAIR_ID>` with the Supra Oracle pair ID for SUPRA/USDT.

## Step 6: Initialize SUPRA Vault

```bash
supra move tool run \
  --function-id "0xabc...::vault::initialize_vault" \
  --type-args "0x1::supra_coin::SupraCoin" \
  --rpc-url https://rpc-testnet.supra.com \
  --private-key <YOUR_PRIVATE_KEY>
```

## Step 7: Register User and Deposit

From a user account:

```bash
# Register user
supra move tool run \
  --function-id "0xabc...::vault::register_user" \
  --rpc-url https://rpc-testnet.supra.com \
  --private-key <USER_KEY>

# Deposit 1 SUPRA (assuming 8 decimals)
supra move tool run \
  --function-id "0xabc...::vault::deposit" \
  --type-args "0x1::supra_coin::SupraCoin" \
  --args u64:100000000 \
  --rpc-url https://rpc-testnet.supra.com \
  --private-key <USER_KEY>
```

## Step 8: Create Limit Buy Strategy

Example: buy 1,000 SUPRA if price drops below 0.00095 USDT.

```bash
supra move tool run \
  --function-id "0xabc...::strategy::create_limit_buy" \
  --type-args "0x1::supra_coin::SupraCoin" "0x1::usdc::USDC" \
  --args u64:100000000000 u128:950000000000000 \
  --rpc-url https://rpc-testnet.supra.com \
  --private-key <USER_KEY>
```

## Step 9: Register AutoFi Task

```bash
supra move automation register \
  --task-max-gas-amount 50000 \
  --task-gas-price-cap 200 \
  --task-expiry-time-secs <UNIX_TIMESTAMP_30_DAYS_FROM_NOW> \
  --task-automation-fee-cap 10000 \
  --function-id "0xabc...::strategy::execute_limit_buy" \
  --type-args "0x1::supra_coin::SupraCoin" "0x1::usdc::USDC" \
  --args address:<USER_ADDRESS> \
  --rpc-url https://rpc-testnet.supra.com \
  --private-key <USER_KEY>
```

After registration, Supra validators will call `execute_limit_buy` periodically.

## Step 10: Verify

Check SupraScan:

- Transaction history for `execute_limit_buy`
- Events: `StrategyExecuted`, `StrategyCancelled`
- Vault balances via `vault::vault_balance<SupraCoin>()`
