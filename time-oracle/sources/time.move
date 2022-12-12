// Copyright (c) Turbos Finance, Inc.
// SPDX-License-Identifier: MIT

module turbos_time_oracle::time {
    //! Monotonically increasing timestamping provided by an off-chain oracle.
    use sui::transfer::{transfer, share_object};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    /// Created as a read-only object on every call to `fun stamp`
    struct Timestamp has key {
        id: UID,
        /// The unix timestamp in ms recorded by the oracle.
        /// Always larger than all timestamp objects with lower index.
        unix_ms: u64,
        /// First timestamp has index 0, second 1, ...
        index: u64,
    }

    /// Created as a single-writer object, unique
    struct AuthorityCap has key, store {
        id: UID,
    }

    // === Getters ===

    public fun unix_ms(t: &Timestamp): u64 {
        t.unix_ms
    }

    public fun unix(t: &Timestamp): u64 {
        t.unix_ms / 1000
    }

    public fun index(t: &Timestamp): u64 {
        t.index
    }

    // === For maintainer ===

    fun init(ctx: &mut TxContext) {
        transfer(AuthorityCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));

        share_object(Timestamp {
            id: object::new(ctx),
            unix_ms: 0,
            index: 0,
        });
    }

    public entry fun stamp(
        _: &mut AuthorityCap,
        timestamp: &mut Timestamp,
        unix_ms_now: u64,
        _ctx: &mut TxContext,
    ) {
        assert!(unix_ms_now > timestamp.unix_ms, 0);
        timestamp.unix_ms = unix_ms_now;
        timestamp.index = timestamp.index + 1;
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
