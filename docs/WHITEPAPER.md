# Zentris Whitepaper (v0.1)

**Intent-Based AutoFi Agent for Native SUPRA**

## Abstract

Zentris is a non-custodial intent-to-automation layer built natively on Supra. Users express DeFi strategies in natural language — for example, *"Buy 1,000 SUPRA if the price drops 5% from 0.001; if the price rises above the target, do not buy and wait until it truly drops."* An off-chain AI agent parses and validates the intent, a Move smart contract enforces the strategy on-chain, Supra Oracle provides real-time price data, and Supra AutoFi executes the strategy natively without external keepers. Deposits and withdrawals are made in **native SUPRA**. Zentris demonstrates how Supra's vertically integrated stack — Oracle, AutoFi, and MoveVM — can power autonomous, keeperless DeFi strategies that are difficult to replicate on other chains.

## 1. Problem

DeFi automation today is fragmented:

- Users must either manually execute trades, run and fund external bots, or rely on custodial services.
- These approaches introduce operational overhead, gas inefficiency, MEV exposure, and trust assumptions.
- No major DeFi stack natively supports natural-language intent.

## 2. Solution

Zentris provides three layers:

1. **Intent Layer** — AI agent parses language into structured schema, validates, simulates, and shows preview before signature.
2. **Execution Layer** — Move contract stores strategies, reads Supra Oracle, executes swaps, enforces cancellation rules.
3. **Automation Layer** — Supra AutoFi triggers execution natively, no external keepers.

**Key property**: the AI agent is a translator, not a custodian. Funds remain in the contract. The agent cannot modify logic or move funds.

## 3. Native SUPRA Vault

Zentris uses **native SUPRA** as the primary vault asset.

- **Deposit**: users deposit SUPRA into the vault.
- **Withdraw**: users withdraw SUPRA at any time.
- **Internal balances**: the vault may hold USDC (or other quote assets) after executions. These fund buy orders.

### Example: Native SUPRA Buy Strategy

User intent:

> *"Buy 1,000 SUPRA if price drops 5% from 0.001. If price rises above target, do not buy — wait until it truly drops."*

Parsed parameters:

```
action: BUY
asset: SUPRA
quote: USDC
quantity: 1,000 SUPRA
reference_price: 0.001 USD
trigger: price <= 0.00095 USD (5% below reference)
persistence: continue waiting until trigger is met
```

Execution logic:

1. Read SUPRA/USDC price from Supra Oracle.
2. If price > 0.00095, do nothing and remain active.
3. If price <= 0.00095 and vault has sufficient USDC, swap USDC for 1,000 SUPRA.
4. If insufficient USDC, emit `InsufficientQuoteBalance` and remain active.
5. After execution, mark strategy filled.

## 4. Architecture

| Component | Role |
|---|---|
| User | Provides intent, signs strategy, deposits/withdraws SUPRA |
| AI Intent Agent | Parses language, validates, simulates, notifies |
| Zentris Move Contract | Stores strategies and balances, enforces rules, executes swaps |
| Supra Oracle | Provides on-chain price feeds |
| Supra Automation Registry | Triggers `execute_strategy` natively |
| Move DEX | Executes swaps |
| Fee Vault | Collects protocol fees transparently |

## 5. Supported Strategies (MVP)

- **Limit Buy**: buy X SUPRA when price <= Y
- **Limit Sell**: sell X SUPRA when price >= Y
- **DCA**: buy X SUPRA every period
- **Conditional Cancel**: cancel if price crosses threshold
- **Rebalance**: maintain target SUPRA/USDC ratio

## 6. Revenue Model

| Stream | Description | MVP |
|---|---|---|
| Execution Fee | 0.1% of swap value | Yes |
| Subscription | Pro tier for advanced features | Yes |
| Strategy Marketplace | Rev-share from creators | Later |
| B2B API/SDK | Licensing for partners | Later |

## 7. Why Supra

Zentris is only feasible with Supra's native stack:

- **Native Oracle** — real-time prices without integration overhead
- **Native AutoFi** — keeperless execution
- **MoveVM** — safe, composable contracts
- **AI/Agent Narrative** — aligns with Supra ecosystem direction
- **Native SUPRA** — simple, aligned user experience

On chains without native automation and oracles, Zentris would require external keepers and oracles, reintroducing the problems it solves.

## 8. Roadmap

- **Phase 1**: SUPRA vault + limit buy strategy + Oracle + AutoFi (current)
- **Phase 2**: AI intent parser, notification, dashboard
- **Phase 3**: Execution fees, marketplace, SDK
- **Phase 4**: ZENTRIS token launch + multi-asset strategies

## 9. Risks

| Risk | Mitigation |
|---|---|
| LLM misparsing | Schema validation, simulation, user preview, signature |
| Prompt injection | Agent cannot alter contract logic or move funds |
| Oracle failure | Supra Oracle native, sanity checks, circuit breaker |
| Automation failure | Retry policy, pause on repeated failure |
| Smart contract bugs | Audit, testnet, bug bounty, value caps |
| Regulatory | Start with execution fees; legal review before performance fees |

## 10. Conclusion

Zentris turns natural-language intent into autonomous, non-custodial DeFi strategies on Supra. By using native SUPRA for deposits, Supra Oracle for prices, and Supra AutoFi for keeperless execution, Zentris showcases Supra's vertically integrated stack. The concept is ready for a MoveVM prototype and aligns with Supra's AI/Agent and AutoFi priorities.
