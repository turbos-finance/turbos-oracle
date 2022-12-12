// Copyright (c) Turbos Finance, Inc.
// SPDX-License-Identifier: MIT

module turbos_price_oracle::price {
    use sui::transfer::{transfer, share_object};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use std::string::{String};
    use std::vector;

    const EFeederAlreadyExists: u64 = 0;
    const EFeederNotExists: u64 = 1;
    const EOnlyFeederCanUpdateFeed: u64 = 2;

    struct PriceFeed<phantom T> has key {
        id: UID,
        symbol: String,
        price: u64,
        ema_price: u64,
        decimal: u8,
        timestamp: u64,
        feeder: vector<address>,
    }

    /// Created as a single-writer object, unique
    struct AuthorityCap has key, store {
        id: UID,
    }

    // === Getters ===

    public fun price<T>(price: &PriceFeed<T>): u64 {
        price.price
    }

    public fun ema_price<T>(price: &PriceFeed<T>): u64 {
        price.price
    }

    public fun decimal<T>(price: &PriceFeed<T>): u8 {
        price.decimal
    }

    public fun timestamp<T>(price: &PriceFeed<T>): u64 {
        price.timestamp
    }

    public fun symbol<T>(price: &PriceFeed<T>): String {
        price.symbol
    }

    // === For maintainer ===
    fun init(ctx: &mut TxContext) {
        transfer(AuthorityCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));
    }

    public entry fun add_feeder<T>(
        _: &mut AuthorityCap,
        price_feed: &mut PriceFeed<T>,
        feeder_address: address,
        _ctx: &mut TxContext,
    ) {
        let (is_exists, _) = vector::index_of(&price_feed.feeder, &feeder_address);
        assert!(!is_exists, EFeederAlreadyExists);
        vector::push_back(&mut price_feed.feeder, feeder_address);
    }

    public entry fun remove_feeder<T>(
        _: &mut AuthorityCap,
        price_feed: &mut PriceFeed<T>,
        feeder_address: address,
        _ctx: &mut TxContext,
    ) {
        let (is_exists, index) = vector::index_of(&price_feed.feeder, &feeder_address);
        assert!(is_exists, EFeederNotExists);
        vector::remove(&mut price_feed.feeder, index);
    }

    public entry fun create_price_feed<T>(
        _: &mut AuthorityCap,
        symbol: String,
        decimal: u8,
        feeder_address: address,
        ctx: &mut TxContext,
    ) {
        let feeder = vector::empty();
        let sender = tx_context::sender(ctx);
        vector::push_back(&mut feeder, sender);
        if (feeder_address != sender && feeder_address != @0x1) {
            vector::push_back(&mut feeder, feeder_address);
        };
        share_object(PriceFeed<T> {
            id: object::new(ctx),
            symbol: symbol,
            price: 0,
            ema_price: 0,
            decimal: decimal, // default 9
            timestamp: 0,
            feeder: feeder,
        });
    }

    public entry fun update_price_feed<T>(
        price_feed: &mut PriceFeed<T>,
        price: u64,
        ema_price: u64, //unix timestamp
        timestamp: u64,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let (is_exists, _) = vector::index_of(&price_feed.feeder, &sender);
        assert!(is_exists, EOnlyFeederCanUpdateFeed);
        price_feed.price = price;
        price_feed.ema_price = ema_price;
        price_feed.timestamp = timestamp;
    }

    public entry fun update_decimal<T>(
        _: &mut AuthorityCap,
        price_feed: &mut PriceFeed<T>,
        decimal: u8,
        _ctx: &mut TxContext,
    ) {
        price_feed.decimal = decimal;
    }

    public entry fun update_symbol<T>(
        _: &mut AuthorityCap,
        price_feed: &mut PriceFeed<T>,
        symbol: String,
        _ctx: &mut TxContext,
    ) {
        price_feed.symbol = symbol;
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    // #[test]
    // public fun test_price() {
    //     use sui::test_scenario::{Self};
    //     use turbos_token::btc::{BTC};
    //     use std::string;
    //     use std::debug;
    //     // create test address representing game admin
    //     let admin = @0x1;
    //     let player = @0x2;
	// 	let player2 = @0x3;

    //     // first transaction to emulate module initialization
    //     let scenario_val = test_scenario::begin(admin);
    //     let scenario = &mut scenario_val;

    //     {
    //         init_for_testing(test_scenario::ctx(scenario));
    //     };


    //     test_scenario::next_tx(scenario, admin);
    //     {
    //         let authority_cap = test_scenario::take_from_sender<AuthorityCap>(scenario);
    //         create_price_feed<BTC>(
    //             &mut authority_cap,
    //             string::utf8(b"BTC"),
    //             9,
    //             player,
    //             test_scenario::ctx(scenario),
    //         );
    //         test_scenario::return_to_sender(scenario, authority_cap);
    //     };

    //     test_scenario::next_tx(scenario, player);
    //     {
    //         let price_feed = test_scenario::take_shared<PriceFeed<BTC>>(scenario);
    //         update_price_feed<BTC>(
    //             &mut price_feed,
    //             100,
    //             200,
    //             1000000,
    //             test_scenario::ctx(scenario),
    //         );
    //         test_scenario::return_shared(price_feed);
    //     };

    //     test_scenario::next_tx(scenario, admin);
    //     {
    //         let price_feed = test_scenario::take_shared<PriceFeed<BTC>>(scenario);
    //         let authority_cap = test_scenario::take_from_sender<AuthorityCap>(scenario);
    //         add_feeder(
    //             &mut authority_cap,
    //             &mut price_feed,
    //             player2,
    //             test_scenario::ctx(scenario)
    //         );
    //         debug::print(&price_feed);
    //         test_scenario::return_to_sender(scenario, authority_cap);
    //         test_scenario::return_shared(price_feed);
    //     };

    //     test_scenario::next_tx(scenario, admin);
    //     {
    //         let price_feed = test_scenario::take_shared<PriceFeed<BTC>>(scenario);
    //         let authority_cap = test_scenario::take_from_sender<AuthorityCap>(scenario);
    //         remove_feeder(
    //             &mut authority_cap,
    //             &mut price_feed,
    //             player,
    //             test_scenario::ctx(scenario)
    //         );
    //         debug::print(&price_feed);
    //         test_scenario::return_to_sender(scenario, authority_cap);
    //         test_scenario::return_shared(price_feed);
    //     };
    //     test_scenario::end(scenario_val);
    // }

}
