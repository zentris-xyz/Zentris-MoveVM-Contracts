module zentris::registry {
    use std::string::String;
    use std::table::{Self, Table};
    use std::type_info::{Self, TypeInfo};
    use supra_framework::signer;

    friend zentris::vault;
    friend zentris::strategy;

    struct AssetInfo has store, drop {
        symbol: String,
        decimals: u8,
        oracle_pair_id: u32,
        active: bool,
    }

    struct AssetRegistry has key {
        supported: Table<TypeInfo, AssetInfo>,
    }

    const E_NOT_ADMIN: u64 = 1;
    const E_ALREADY_REGISTERED: u64 = 2;
    const E_NOT_SUPPORTED: u64 = 3;
    const E_INACTIVE: u64 = 4;

    fun init_module(admin: &signer) {
        move_to(admin, AssetRegistry {
            supported: table::new<TypeInfo, AssetInfo>(),
        });
    }

    public entry fun add_supported_asset<T>(
        admin: &signer,
        symbol: String,
        decimals: u8,
        oracle_pair_id: u32,
    ) acquires AssetRegistry {
        assert!(signer::address_of(admin) == @zentris, E_NOT_ADMIN);

        let registry = borrow_global_mut<AssetRegistry>(@zentris);
        let info = type_info::type_of<T>();

        assert!(!table::contains(&registry.supported, info), E_ALREADY_REGISTERED);

        table::add(&mut registry.supported, info, AssetInfo {
            symbol,
            decimals,
            oracle_pair_id,
            active: true,
        });
    }

    public entry fun set_asset_active<T>(
        admin: &signer,
        active: bool,
    ) acquires AssetRegistry {
        assert!(signer::address_of(admin) == @zentris, E_NOT_ADMIN);

        let registry = borrow_global_mut<AssetRegistry>(@zentris);
        let info = type_info::type_of<T>();
        assert!(table::contains(&registry.supported, info), E_NOT_SUPPORTED);

        let asset = table::borrow_mut(&mut registry.supported, info);
        asset.active = active;
    }

    #[view]
    public fun is_supported<T>(): bool acquires AssetRegistry {
        let registry = borrow_global<AssetRegistry>(@zentris);
        let info = type_info::type_of<T>();
        if (!table::contains(&registry.supported, info)) {
            return false
        };
        table::borrow(&registry.supported, info).active
    }

    #[view]
    public fun get_asset_info<T>(): AssetInfo acquires AssetRegistry {
        let registry = borrow_global<AssetRegistry>(@zentris);
        let info = type_info::type_of<T>();
        assert!(table::contains(&registry.supported, info), E_NOT_SUPPORTED);
        *table::borrow(&registry.supported, info)
    }

    public(friend) fun assert_supported<T>() acquires AssetRegistry {
        let registry = borrow_global<AssetRegistry>(@zentris);
        let info = type_info::type_of<T>();
        assert!(table::contains(&registry.supported, info), E_NOT_SUPPORTED);
        assert!(table::borrow(&registry.supported, info).active, E_INACTIVE);
    }

    public(friend) fun oracle_pair_id<T>(): u32 acquires AssetRegistry {
        let registry = borrow_global<AssetRegistry>(@zentris);
        let info = type_info::type_of<T>();
        assert!(table::contains(&registry.supported, info), E_NOT_SUPPORTED);
        table::borrow(&registry.supported, info).oracle_pair_id
    }
}
