// Copyright (c) Turbos Finance, Inc.
// SPDX-License-Identifier: MIT

module turbos_aum_oracle::aum {
    use sui::transfer::{transfer, share_object};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    struct AUM has key {
        id: UID,
        amount: u64,
        last_update_time: u64, //unix timestamp
    }

    /// Created as a single-writer object, unique
    struct AuthorityCap has key, store {
        id: UID,
    }

    // === Getters ===

    public fun amount(aum: &AUM): u64 {
        aum.amount
    }

    public fun last_update_time(aum: &AUM): u64 {
        aum.last_update_time
    }

    // === For maintainer ===
    fun init(ctx: &mut TxContext) {
        transfer(AuthorityCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));

        share_object(AUM {
            id: object::new(ctx),
            amount: 0,
            last_update_time: 0,
        });
    }

    public entry fun update(
        _: &mut AuthorityCap,
        aum: &mut AUM,
        amount: u64,
        unix_now: u64,
        _ctx: &mut TxContext,
    ) {
        aum.amount = amount;
        aum.last_update_time = unix_now;
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
