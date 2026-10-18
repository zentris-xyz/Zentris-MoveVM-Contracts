# Zentris — Architecture

## Overview

Zentris is a three-layer system:

1. **Intent Layer (off-chain)** — AI agent parses natural-language instructions into structured strategy parameters.
2. **Execution Layer (on-chain)** — Move contracts store strategies, enforce rules, and execute swaps.
3. **Automation Layer (Supra AutoFi)** — Validators trigger execution natively, no external keepers.

## Components

### Registry (`registry.move`)

Global whitelist of supported assets. Each asset has:

- `symbol` — display name
- `decimals` — coin decimals
- `oracle_pair_id` — Supra Oracle pair ID
- `active` — whether deposits/strategies are allowed

Assets are added by calling `add_supported_asset<T>()`. Once added, the asset is supported forever (or until `set_asset_active(false)` is called).

### Vault (`vault.move`)

Per-asset vault holding `Balance<T>` for all users combined. Per-user balances tracked in `UserVault.balances: Table<TypeInfo, u64>`.

- `deposit<T>(user, amount)` — pull from user, merge into vault, credit user
- `withdraw<T>(user, amount)` — debit user, extract from vault, deposit to user
- `withdraw_for_strategy<T>` — internal, called by strategy
- `deposit_for_strategy<T>` — internal, called by strategy

### Strategy (`strategy.move`)

`LimitBuyStrategy<Base, Quote>` stores:

- `owner` — strategy owner
- `quantity` — amount of base asset to buy
- `trigger_price` — price at which to buy
- `active` — whether strategy is live
- `last_executed` — timestamp of last execution

`execute_limit_buy<Base, Quote>(owner)` is the AutoFi entry point:

1. Read price from Supra Oracle
2. If price > trigger, return (do nothing, stay active)
3. If price <= trigger, pull Quote from vault, swap for Base, deposit Base back

## Why Generic Vault

Using `Vault<phantom T>` and `UserVault.balances: Table<TypeInfo, u64>` allows adding new assets (e.g. ZENTRIS) without redeploying. All that's needed is one transaction: `add_supported_asset<ZentrisCoin>()`.

## Automation Flow

```
1. User calls create_limit_buy<Base, Quote>(quantity, trigger_price)
2. Zentris registers execute_limit_buy<Base, Quote> with Supra Automation Registry
3. Validator runs execute_limit_buy periodically
4. Contract reads Oracle, decides to swap or wait
5. On success, emits event; on failure, stays active
```

## Security

- **Non-custodial**: AI agent never holds funds, cannot alter logic
- **Type-safe**: Move's generic type system prevents asset confusion
- **Registry-controlled**: Only admin can add assets
- **Circuit breaker**: `active` flag allows pause at any time
- **Oracle sanity**: rejects price = 0

## Future Extensions

- DEX router integration (swap Quote → Base)
- Multi-step strategies (DCA, rebalancing)
- Strategy composition (nested intents)
- ZENTRIS token vault and fee distribution
- Cross-strategy gas optimization
