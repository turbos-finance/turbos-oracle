// Copyright (c) Turbos Finance, Inc.
// SPDX-License-Identifier: MIT

module turbos_oracle_samples::price {
	use std::string::{String};
	use sui::object::{Self, UID};
	use turbos_price_oracle::price::{Self, PriceFeed};
	use sui::transfer;
	use sui::tx_context::{Self, TxContext};

	struct CurrentTokenPrice has key, store {
		id: UID,
		symbol: String,
        price: u64,
        decimal: u8,
	}

	entry fun test_price_feed<T> (
        price_feed: &PriceFeed<T>,
        ctx: &mut TxContext
    ) {
		let token_symbol = price::symbol(price_feed);
		let token_price = price::price(price_feed);
        let token_decimal = price::decimal(price_feed);

		transfer::transfer(CurrentTokenPrice { 
			id: object::new(ctx),
			symbol: token_symbol,
			price: token_price,
			decimal: token_decimal,
		}, tx_context::sender(ctx));
    }
}