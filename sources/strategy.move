module zentris::strategy {
    use supra_framework::coin;
    use supra_framework::signer;
    use supra_framework::timestamp;
    use supra_oracle::supra_oracle_storage;
    use dexlyn_swap::router;
    use dexlyn_swap::curves::Uncorrelated;
    use std::type_info;

    struct LimitBuyStrategy<phantom Base, phantom Quote> has key {
        owner: address,
        quantity: u64,
        trigger_price: u128,
        active: bool,
        last_executed: u64,
    }

    const E_NOT_OWNER: u64 = 20;
    const E_NOT_ACTIVE: u64 = 21;
    const E_PRICE_NOT_MET: u64 = 22;
    const E_INVALID_PRICE: u64 = 23;
    const E_INSUFFICIENT_QUOTE: u64 = 24;

    public entry fun create_limit_buy<Base, Quote>(
        owner: &signer,
        quantity: u64,
        trigger_price: u128,
    ) {
        zentris::registry::assert_supported<Base>();
        zentris::registry::assert_supported<Quote>();

        let addr = signer::address_of(owner);
        move_to(owner, LimitBuyStrategy<Base, Quote> {
            owner: addr,
            quantity,
            trigger_price,
            active: true,
            last_executed: 0,
        });
    }

    /// AutoFi Entry Point — didaftarkan ke Supra Automation Registry.
    /// Signature: satu address, cocok untuk automation registration.
    public entry fun execute_limit_buy<Base, Quote>(
        owner: address,
    ) acquires LimitBuyStrategy {
        let strategy = borrow_global_mut<LimitBuyStrategy<Base, Quote>>(owner);
        assert!(strategy.active, E_NOT_ACTIVE);

        // Baca harga dari Supra Oracle (push model)
        let pair_id = zentris::registry::oracle_pair_id<Base>();
        let (price, _decimals, _round, _timestamp) =
            supra_oracle_storage::get_price(pair_id);

        assert!(price > 0, E_INVALID_PRICE);

        // "Jangan beli, tunggu hingga benar-benar turun."
        if (price > strategy.trigger_price) {
            return
        };

        // Cek saldo Quote user di vault
        let user_quote_balance = zentris::vault::balance_of<Quote>(owner);
        assert!(user_quote_balance >= strategy.quantity, E_INSUFFICIENT_QUOTE);

        // Tarik Quote dari vault user
        let quote_coin = zentris::vault::withdraw_for_strategy<Quote>(
            owner,
            strategy.quantity,
        );

        // DEX Swap: Quote -> Base menggunakan Dexlyn Router
        // Hitung jumlah Base yang akan diterima
        let base_amount_out = router::get_amount_out<Quote, Base, Uncorrelated>(
            strategy.quantity
        );

        // Slippage protection: minimal 1% dari estimasi
        let min_base_out = base_amount_out - (base_amount_out / 100);

        // Eksekusi swap
        let base_coin = router::swap_exact_coin_for_coin<Quote, Base, Uncorrelated>(
            quote_coin,
            min_base_out,
        );

        // Deposit Base hasil swap ke vault user
        zentris::vault::deposit_for_strategy<Base>(owner, base_coin);

        strategy.last_executed = timestamp::now_seconds();
        strategy.active = false; // limit buy sekali jalan
    }

    public entry fun cancel<Base, Quote>(owner: &signer) acquires LimitBuyStrategy {
        let addr = signer::address_of(owner);
        let strategy = borrow_global_mut<LimitBuyStrategy<Base, Quote>>(addr);
        assert!(strategy.owner == addr, E_NOT_OWNER);
        strategy.active = false;
    }

    #[view]
    public fun status<Base, Quote>(owner: address): (u64, u128, bool, u64) acquires LimitBuyStrategy {
        let s = borrow_global<LimitBuyStrategy<Base, Quote>>(owner);
        (s.quantity, s.trigger_price, s.active, s.last_executed)
    }
}
