# Zentris

**Intent-Based AutoFi Agent for Native SUPRA**

Zentris turns natural-language DeFi instructions into autonomous, non-custodial on-chain strategies on Supra. Users say what they want — *"Buy 1,000 SUPRA if price drops 5% from 0.001; if price rises above target, do not buy and wait until it truly drops"* — and Zentris enforces the intent on-chain using Supra Oracle and Supra AutoFi.

## Why Supra

Zentris is only feasible because Supra provides:

- **Native Oracle** — real-time price data without third-party integration
- **Native AutoFi** — keeperless execution at the validator level
- **MoveVM** — safe, composable smart contracts
- **Native SUPRA** — simple, aligned user experience

On chains without native automation and oracle infrastructure, Zentris would require external keepers and oracles, reintroducing the very problems it aims to solve.

## Architecture

```
User → AI Intent Agent (off-chain)
       ↓ create_limit_buy
       ↓
   Zentris Move Contract
     ├── registry.move    (asset whitelist)
     ├── vault.move       (per-user, per-asset balances)
     └── strategy.move    (limit buy, execution logic)
       ↑
       │ triggered by
       │
   Supra Automation Registry
       ↑
       │ reads price
       │
   Supra Oracle
```

## Quick Start

```bash
# Build
supra move tool build --package-dir .

# Test
supra move tool test --package-dir .

# Publish to testnet
supra move tool publish --package-dir . --rpc-url https://rpc-testnet.supra.com
```

## Repo Structure

| Path | Purpose |
|---|---|
| `sources/registry.move` | Asset whitelist and metadata |
| `sources/vault.move` | Generic vault for SUPRA and future tokens |
| `sources/strategy.move` | Limit buy strategy + AutoFi entry point |
| `docs/ARCHITECTURE.md` | Technical deep dive |
| `docs/DEPLOYMENT.md` | Step-by-step deploy |
| `docs/WHITEPAPER.md` | Project whitepaper |

## Adding ZENTRIS Later

No redeploy needed. When ZENTRIS launches:

1. Launch token + liquidity pool.
2. Call `registry::add_supported_asset<ZentrisCoin>("ZENTRIS", 8, <pair_id>)`.
3. Call `vault::initialize_vault<ZentrisCoin>(admin)`.
4. Users can deposit ZENTRIS immediately.
5. Register AutoFi task for ZENTRIS strategies.

## Roadmap

- [x] Registry + generic vault + limit buy strategy
- [ ] Supra Oracle integration (testnet verified)
- [ ] Supra AutoFi registration
- [ ] DEX router integration
- [ ] AI intent parser (off-chain)
- [ ] Dashboard and notifications
- [ ] ZENTRIS token launch
- [ ] Strategy marketplace

## License

MIT
