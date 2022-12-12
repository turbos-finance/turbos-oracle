// Copyright (c) Turbos Finance, Inc.
// SPDX-License-Identifier: MIT

module turbos_oracle_samples::timestamp {
	use sui::object::{Self, UID};
	use turbos_time_oracle::time::{Self, Timestamp};
	use sui::transfer;
	use sui::tx_context::{Self, TxContext};

	struct CurrentTime has key, store {
		id: UID,
		time_ms: u64,
        time: u64,
	}

	entry fun test_time_feed (
        timestamp: &Timestamp,
        ctx: &mut TxContext
    ) {
		let current_time_ms = time::unix_ms(timestamp);
		let current_time = time::unix(timestamp);

		transfer::transfer(CurrentTime { 
			id: object::new(ctx),
			time_ms: current_time_ms,
			time: current_time,
		}, tx_context::sender(ctx));
    }
}