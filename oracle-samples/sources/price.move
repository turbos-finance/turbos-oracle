// Copyright (c) Turbos Finance, Inc.
// SPDX-License-Identifier: MIT

module turbos_oracle_samples::price {
	use std::string::{Self, String};
	use sui::object::{Self, UID};
	use turbos_price_oracle::turbos_price::{Self, PriceFeedStorage};
	use sui::transfer;
	use sui::tx_context::{Self, TxContext};

	struct CurrentTokenPrice has key, store {
		id: UID,
		symbol: String,
        price: u64,
        decimal: u8,
	}

	entry fun test_price_feed (
        price_feed_storage: &PriceFeedStorage,
        ctx: &mut TxContext
    ) {
        let btc_price_id = string::utf8(b"fbd7c495fcc83ec7ce6522eb44a453a70f88ef64664f1ed49e011be87ffe3525");
		let token_symbol = turbos_price::get_symbol(price_feed_storage, btc_price_id);
		let token_price = turbos_price::get_price(price_feed_storage, btc_price_id);
		let token_decimal = turbos_price::get_decimal(price_feed_storage, btc_price_id);
		transfer::transfer(CurrentTokenPrice { 
			id: object::new(ctx),
			symbol: token_symbol,
			price: token_price,
			decimal: token_decimal,
		}, tx_context::sender(ctx));
    }
}