module MyModule::TokenVesting {
    use aptos_framework::signer;
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    struct VestingSchedule has store, key {
        beneficiary: address,
        total_amount: u64,
        released: u64,
        start_time: u64,
        duration: u64,
    }

    // Creates a new vesting schedule for a beneficiary.
    public fun create_vesting_schedule(
        owner: &signer,
        beneficiary: address,
        total_amount: u64,
        start_time: u64,
        duration: u64
    ) {
        let schedule = VestingSchedule {
            beneficiary,
            total_amount,
            released: 0,
            start_time,
            duration,
        };
        move_to(owner, schedule);
    }

    // Releases tokens that have vested up to the current time.
    public fun release_tokens(
        claimer: &signer
    ) acquires VestingSchedule {
        let schedule = borrow_global_mut<VestingSchedule>(signer::address_of(claimer));
        let current_time = timestamp::now_seconds();
        let elapsed = if (current_time > schedule.start_time) {
            current_time - schedule.start_time
        } else {
            0
        };
        let vested = if (elapsed >= schedule.duration) {
            schedule.total_amount
        } else {
            (schedule.total_amount * elapsed) / schedule.duration
        };
        let unreleased = vested - schedule.released;
        schedule.released = schedule.released + unreleased;
        let payout = coin::withdraw<AptosCoin>(claimer, unreleased);
        coin::deposit<AptosCoin>(schedule.beneficiary, payout);
    }
}
