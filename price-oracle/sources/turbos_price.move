// Copyright (c) Turbos Finance, Inc.
// SPDX-License-Identifier: MIT

module turbos_price_oracle::turbos_price {
    use sui::transfer::{transfer, share_object};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use std::vector;
    use std::hash;
    use sui::dynamic_object_field;

    const EFeederAlreadyExists: u64 = 0;
    const EFeederNotExists: u64 = 1;
    const EOnlyFeederCanUpdateFeed: u64 = 2;
    const EPriceFeedAlreadyExists: u64 = 3;
    const EPriceFeedNotExists: u64 = 4;

    struct PriceFeed has key, store{
        id: UID,
        symbol: String,
        price: u64,
        ema_price: u64,
        decimal: u8,
        timestamp: u64,
    }

    struct PriceFeedStorage has key, store {
        id: UID,
        feeders: vector<address>,
    }

    /// Created as a single-writer object, unique
    struct AuthorityCap has key, store {
        id: UID,
    }

    // === Getters ===
    public fun get_price(price_feed_storage: &PriceFeedStorage, price_id: String): u64 {
        assert!(dynamic_object_field::exists_(&price_feed_storage.id, price_id), EPriceFeedNotExists);

        let price_feed = dynamic_object_field::borrow<String, PriceFeed>(&price_feed_storage.id, price_id);
        price_feed.price
    }

    public fun get_ema_price(price_feed_storage: &PriceFeedStorage, price_id: String): u64 {
        assert!(dynamic_object_field::exists_(&price_feed_storage.id, price_id), EPriceFeedNotExists);

        let price_feed = dynamic_object_field::borrow<String, PriceFeed>(&price_feed_storage.id, price_id);
        price_feed.ema_price
    }

    public fun get_decimal(price_feed_storage: &PriceFeedStorage, price_id: String): u8 {
        assert!(dynamic_object_field::exists_(&price_feed_storage.id, price_id), EPriceFeedNotExists);

        let price_feed = dynamic_object_field::borrow<String, PriceFeed>(&price_feed_storage.id, price_id);
        price_feed.decimal
    }

    public fun get_timestamp(price_feed_storage: &PriceFeedStorage, price_id: String): u64 {
        assert!(dynamic_object_field::exists_(&price_feed_storage.id, price_id), EPriceFeedNotExists);

        let price_feed = dynamic_object_field::borrow<String, PriceFeed>(&price_feed_storage.id, price_id);
        price_feed.timestamp
    }

    public fun get_symbol(price_feed_storage: &PriceFeedStorage, price_id: String): String {
        assert!(dynamic_object_field::exists_(&price_feed_storage.id, price_id), EPriceFeedNotExists);

        let price_feed = dynamic_object_field::borrow<String, PriceFeed>(&price_feed_storage.id, price_id);
        price_feed.symbol
    }

    // === For maintainer ===
    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        transfer(AuthorityCap {
            id: object::new(ctx),
        }, sender);

        let feeders = vector::empty();
        vector::push_back(&mut feeders, sender);
        share_object(PriceFeedStorage {
           id: object::new(ctx), 
           feeders: feeders,
        });
    }

    entry fun add_feeder(
        _: &mut AuthorityCap,
        price_feed_storage: &mut PriceFeedStorage,
        feeder_address: address,
        _ctx: &mut TxContext,
    ) {
        let (is_exists, _) = vector::index_of(&price_feed_storage.feeders, &feeder_address);
        assert!(!is_exists, EFeederAlreadyExists);
        vector::push_back(&mut price_feed_storage.feeders, feeder_address);
    }

    entry fun remove_feeder(
        _: &mut AuthorityCap,
        price_feed_storage: &mut PriceFeedStorage,
        feeder_address: address,
        _ctx: &mut TxContext,
    ) {
        let (is_exists, index) = vector::index_of(&price_feed_storage.feeders, &feeder_address);
        assert!(is_exists, EFeederNotExists);
        vector::remove(&mut price_feed_storage.feeders, index);
    }

    entry fun create_price_feed(
        _: &mut AuthorityCap,
        price_feed_storage: &mut PriceFeedStorage,
        symbol: String,
        decimal: u8,
        ctx: &mut TxContext,
    ) {
        let price_id = get_price_id(symbol);

        assert!(!dynamic_object_field::exists_(&price_feed_storage.id, price_id), EPriceFeedAlreadyExists);
        dynamic_object_field::add(&mut price_feed_storage.id, price_id, PriceFeed {
            id: object::new(ctx),
            symbol: symbol,
            price: 0,
            ema_price: 0,
            decimal: decimal, // default 9
            timestamp: 0,
        });
    }

    entry fun update_price_feed_decimal(
        _: &mut AuthorityCap,
        price_feed_storage: &mut PriceFeedStorage,
        price_id: String,
        decimal: u8,
        _ctx: &mut TxContext,
    ) {
        assert!(dynamic_object_field::exists_(&price_feed_storage.id, price_id), EPriceFeedNotExists);

        let price_feed = dynamic_object_field::borrow_mut<String, PriceFeed>(&mut price_feed_storage.id, price_id);
        price_feed.decimal = decimal;
    }

    entry fun update_price(
        price_feed_storage: &mut PriceFeedStorage,
        price_id: String,
        price: u64,
        ema_price: u64, //unix timestamp
        timestamp: u64,
        ctx: &mut TxContext,
    ) {
        assert!(dynamic_object_field::exists_(&price_feed_storage.id, price_id), EPriceFeedNotExists);
        let sender = tx_context::sender(ctx);
        let (is_exists, _) = vector::index_of(&price_feed_storage.feeders, &sender);
        assert!(is_exists, EOnlyFeederCanUpdateFeed);

        let price_feed = dynamic_object_field::borrow_mut<String, PriceFeed>(&mut price_feed_storage.id, price_id);
        price_feed.price = price;
        price_feed.ema_price = ema_price;
        price_feed.timestamp = timestamp;
    }

    public fun get_price_id(symbol: String): String {
        let hash = hash::sha2_256(*string::bytes(&symbol));
        bytes_to_hexstring(&hash)
    }

    fun bytes_to_hexstring(bytes: &vector<u8>): String {
        let r = &mut string::utf8(b"");

        let index = 0;
        while (index < vector::length(bytes)) {
            let byte = vector::borrow(bytes, index);
            string::append(r, u64_to_hexstring((*byte as u64)));

            index = index + 1;
        };

        *r
    }

    fun u64_to_hexstring(num: u64): String {
        let a1 = num / 16;
        let a2 = num % 16;
        let alpha = &b"0123456789abcdef";
        let r = &mut b"";
        vector::push_back(r, *vector::borrow(alpha, a1));
        vector::push_back(r, *vector::borrow(alpha, a2));

        string::utf8(*r)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test]
    #[expected_failure(abort_code = EOnlyFeederCanUpdateFeed)]
    public fun test_price() {
        use sui::test_scenario::{Self};
        use std::string;
        // use std::debug;
        // create test address representing game admin
        let admin = @0x1;
        let player = @0x2;
		let player2 = @0x3;
        let btc_symbol = string::utf8(b"BTCUSD");

        // first transaction to emulate module initialization
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        {
            init_for_testing(test_scenario::ctx(scenario));
        };


        test_scenario::next_tx(scenario, admin);
        {
            let price_feed_storage = test_scenario::take_shared<PriceFeedStorage>(scenario);
            let authority_cap = test_scenario::take_from_sender<AuthorityCap>(scenario);
            create_price_feed(
                &mut authority_cap,
                &mut price_feed_storage,
                btc_symbol,
                9,
                test_scenario::ctx(scenario),
            );
            test_scenario::return_to_sender(scenario, authority_cap);
            test_scenario::return_shared(price_feed_storage);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let price_feed_storage = test_scenario::take_shared<PriceFeedStorage>(scenario);
            let authority_cap = test_scenario::take_from_sender<AuthorityCap>(scenario);
            let price_id = get_price_id(btc_symbol);
            update_price_feed_decimal(
                &mut authority_cap,
                &mut price_feed_storage,
                price_id,
                8,
                test_scenario::ctx(scenario),
            );
            test_scenario::return_to_sender(scenario, authority_cap);
            test_scenario::return_shared(price_feed_storage);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let price_feed_storage = test_scenario::take_shared<PriceFeedStorage>(scenario);
            let price_id = get_price_id(btc_symbol);
            update_price(
                &mut price_feed_storage,
                price_id,
                100,
                200,
                1000000,
                test_scenario::ctx(scenario),
            );
            let price = get_price(&price_feed_storage, price_id);
            assert!(price == 100, 0);
            test_scenario::return_shared(price_feed_storage);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let price_feed_storage = test_scenario::take_shared<PriceFeedStorage>(scenario);
            let authority_cap = test_scenario::take_from_sender<AuthorityCap>(scenario);
            add_feeder(
                &mut authority_cap,
                &mut price_feed_storage,
                player,
                test_scenario::ctx(scenario)
            );
            test_scenario::return_to_sender(scenario, authority_cap);
            test_scenario::return_shared(price_feed_storage);
        };

        test_scenario::next_tx(scenario, player);
        {
            let price_feed_storage = test_scenario::take_shared<PriceFeedStorage>(scenario);
            let price_id = get_price_id(btc_symbol);
            update_price(
                &mut price_feed_storage,
                price_id,
                100,
                200,
                1000000,
                test_scenario::ctx(scenario),
            );
            let price = get_price(&price_feed_storage, price_id);
            assert!(price == 100, 0);
            test_scenario::return_shared(price_feed_storage);
        };

        test_scenario::next_tx(scenario, player2);
        {
            let price_feed_storage = test_scenario::take_shared<PriceFeedStorage>(scenario);
            let price_id = get_price_id(btc_symbol);
            update_price(
                &mut price_feed_storage,
                price_id,
                100,
                200,
                1000000,
                test_scenario::ctx(scenario),
            );
            let price = get_price(&price_feed_storage, price_id);
            assert!(price == 100, 0);
            test_scenario::return_shared(price_feed_storage);
        };
        test_scenario::end(scenario_val);
    }

}
