module zentris::vault {
    use supra_framework::coin::{Self, Coin, Balance};
    use supra_framework::signer;
    use supra_framework::account;
    use std::table::{Self, Table};
    use std::type_info::{Self, TypeInfo};
    use std::signer;

    friend zentris::strategy;
    friend zentris::registry;

    struct Vault<phantom T> has key {
        balance: Balance<T>,
    }

    struct UserVault has key {
        balances: Table<TypeInfo, u64>,
    }

    const E_NOT_REGISTERED: u64 = 10;
    const E_INSUFFICIENT: u64 = 11;
    const E_VAULT_NOT_INITIALIZED: u64 = 12;
    const E_NOT_ADMIN: u64 = 13;

    /// Resource account untuk vault, dibuat sekali saat deploy.
    struct VaultSignerCap has key {
        cap: account::SignerCapability,
    }

    fun init_module(admin: &signer) {
        // Buat resource account untuk vault
        let (vault_signer, vault_cap) = account::create_resource_account(
            admin, b"zentris_vault"
        );
        move_to(admin, VaultSignerCap { cap: vault_cap });
        // Vault per aset dibuat saat add_supported_asset dipanggil
        let _ = vault_signer;
    }

    /// Dipanggil oleh registry saat aset baru didaftarkan.
    /// Membuat Vault<T> di resource account.
    public(friend) fun initialize_vault<T>(admin: &signer) {
        let vault_addr = account::create_resource_address(
            &signer::address_of(admin), b"zentris_vault"
        );
        if (exists<Vault<T>>(vault_addr)) {
            return
        };
        let vault_signer = account::create_signer_with_capability(
            &borrow_global<VaultSignerCap>(@zentris).cap
        );
        move_to(&vault_signer, Vault<T> {
            balance: coin::zero<T>(),
        });
    }

    public entry fun register_user(user: &signer) {
        let addr = signer::address_of(user);
        if (!exists<UserVault>(addr)) {
            move_to(user, UserVault {
                balances: table::new<TypeInfo, u64>(),
            });
        };
    }

    public entry fun deposit<T>(
        user: &signer,
        amount: u64,
    ) acquires Vault, UserVault, VaultSignerCap {
        zentris::registry::assert_supported<T>();

        let addr = signer::address_of(user);
        assert!(exists<UserVault>(addr), E_NOT_REGISTERED);

        let vault_addr = account::create_resource_address(
            &signer::address_of(user), b"zentris_vault"
        );
        // Gunakan alamat resource account yang benar
        let actual_vault_addr = account::create_resource_address(
            &@zentris, b"zentris_vault"
        );
        assert!(exists<Vault<T>>(actual_vault_addr), E_VAULT_NOT_INITIALIZED);

        let coin = coin::withdraw<T>(user, amount);

        let vault = borrow_global_mut<Vault<T>>(actual_vault_addr);
        coin::merge(&mut vault.balance, coin);

        let uv = borrow_global_mut<UserVault>(addr);
        let info = type_info::type_of<T>();
        let current = if (table::contains(&uv.balances, info)) {
            *table::borrow(&uv.balances, info)
        } else { 0 };
        if (table::contains(&uv.balances, info)) {
            *table::borrow_mut(&mut uv.balances, info) = current + amount;
        } else {
            table::add(&mut uv.balances, info, current + amount);
        };
    }

    public entry fun withdraw<T>(
        user: &signer,
        amount: u64,
    ) acquires Vault, UserVault {
        let addr = signer::address_of(user);
        assert!(exists<UserVault>(addr), E_NOT_REGISTERED);

        let uv = borrow_global_mut<UserVault>(addr);
        let info = type_info::type_of<T>();
        assert!(table::contains(&uv.balances, info), E_INSUFFICIENT);

        let balance = table::borrow_mut(&mut uv.balances, info);
        assert!(*balance >= amount, E_INSUFFICIENT);
        *balance = *balance - amount;

        let actual_vault_addr = account::create_resource_address(
            &@zentris, b"zentris_vault"
        );
        let vault = borrow_global_mut<Vault<T>>(actual_vault_addr);
        let coin = coin::extract(&mut vault.balance, amount);
        coin::deposit(addr, coin);
    }

    #[view]
    public fun balance_of<T>(user: address): u64 acquires UserVault {
        if (!exists<UserVault>(user)) {
            return 0
        };
        let uv = borrow_global<UserVault>(user);
        let info = type_info::type_of<T>();
        if (!table::contains(&uv.balances, info)) {
            return 0
        };
        *table::borrow(&uv.balances, info)
    }

    #[view]
    public fun vault_balance<T>(): u64 acquires Vault {
        let actual_vault_addr = account::create_resource_address(
            &@zentris, b"zentris_vault"
        );
        if (!exists<Vault<T>>(actual_vault_addr)) {
            return 0
        };
        coin::value(&borrow_global<Vault<T>>(actual_vault_addr).balance)
    }

    public(friend) fun withdraw_for_strategy<T>(
        user: address,
        amount: u64,
    ): Coin<T> acquires Vault, UserVault {
        let uv = borrow_global_mut<UserVault>(user);
        let info = type_info::type_of<T>();
        assert!(table::contains(&uv.balances, info), E_INSUFFICIENT);

        let balance = table::borrow_mut(&mut uv.balances, info);
        assert!(*balance >= amount, E_INSUFFICIENT);
        *balance = *balance - amount;

        let actual_vault_addr = account::create_resource_address(
            &@zentris, b"zentris_vault"
        );
        let vault = borrow_global_mut<Vault<T>>(actual_vault_addr);
        coin::extract(&mut vault.balance, amount)
    }

    public(friend) fun deposit_for_strategy<T>(
        user: address,
        coin: Coin<T>,
    ) acquires Vault, UserVault {
        let amount = coin::value(&coin);
        let actual_vault_addr = account::create_resource_address(
            &@zentris, b"zentris_vault"
        );
        let vault = borrow_global_mut<Vault<T>>(actual_vault_addr);
        coin::merge(&mut vault.balance, coin);

        let uv = borrow_global_mut<UserVault>(user);
        let info = type_info::type_of<T>();
        let current = if (table::contains(&uv.balances, info)) {
            *table::borrow(&uv.balances, info)
        } else { 0 };
        if (table::contains(&uv.balances, info)) {
            *table::borrow_mut(&mut uv.balances, info) = current + amount;
        } else {
            table::add(&mut uv.balances, info, current + amount);
        };
    }
}
