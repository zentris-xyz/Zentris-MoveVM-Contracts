#[test_only]
module zentris::vault_tests {
    use supra_framework::supra_coin::SupraCoin;
    use supra_framework::coin;
    use supra_framework::account;
    use std::string::utf8;

    #[test(admin = @zentris, user = @0x1234)]
    fun test_deposit_and_withdraw_supra(admin: &signer, user: &signer) {
        // Init module
        zentris::registry::init_module(admin);
        zentris::vault::init_module(admin);

        // Register SUPRA
        zentris::registry::add_supported_asset<SupraCoin>(
            admin,
            utf8(b"SUPRA"),
            8,
            0,
        );

        // Init vault for SUPRA
        zentris::vault::initialize_vault<SupraCoin>(admin);

        // User register + deposit
        zentris::vault::register_user(user);
        let user_addr = @0x1234;
        // Mint SUPRA to user (requires test-only mint)
        let coins = coin::mint<SupraCoin>(1000);
        coin::deposit(user_addr, coins);

        zentris::vault::deposit<SupraCoin>(user, 500);
        assert!(zentris::vault::balance_of<SupraCoin>(user_addr) == 500, 1);
        assert!(zentris::vault::vault_balance<SupraCoin>() == 500, 2);

        // Withdraw
        zentris::vault::withdraw<SupraCoin>(user, 200);
        assert!(zentris::vault::balance_of<SupraCoin>(user_addr) == 300, 3);
        assert!(zentris::vault::vault_balance<SupraCoin>() == 300, 4);
    }

    #[test(admin = @zentris, user = @0x1234)]
    #[expected_failure(abort_code = 3)]
    fun test_deposit_unsupported_asset(admin: &signer, user: &signer) {
        zentris::registry::init_module(admin);
        zentris::vault::init_module(admin);
        zentris::vault::register_user(user);

        // Tanpa register SUPRA, deposit harus gagal
        zentris::vault::deposit<SupraCoin>(user, 100);
    }
}
