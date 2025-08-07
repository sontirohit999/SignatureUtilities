module rohit_addr::signature_utils {
    use std::vector;
    use std::signer;
    use aptos_std::ed25519;
    use aptos_std::hash;
    
    use aptos_framework::account;

    /// Error codes
    const E_INVALID_SIGNATURE: u64 = 1;
    const E_INVALID_PUBLIC_KEY: u64 = 2;

    /// Structure to store signature data
    struct SignatureData has key, store {
        message_hash: vector<u8>,
        signature: vector<u8>,
        public_key: vector<u8>,
        timestamp: u64,
    }

    /// Generate and store a signature for a given message
    public entry fun generate_signature(
        account: &signer,
        message: vector<u8>,
        signature: vector<u8>,
        public_key: vector<u8>,
    ) {
        let account_addr = signer::address_of(account);
        let message_hash = hash::sha3_256(message);
        let timestamp = aptos_framework::timestamp::now_seconds();

        let sig_data = SignatureData {
            message_hash,
            signature,
            public_key,
            timestamp,
        };

        if (exists<SignatureData>(account_addr)) {
            move_from<SignatureData>(account_addr);
        };

        move_to(account, sig_data);
    }

    /// Verify a signature against stored signature data
    public fun verify_signature(
        account_addr: address,
        message: vector<u8>,
    ): bool acquires SignatureData {
        if (!exists<SignatureData>(account_addr)) {
            return false
        };

        let sig_data = borrow_global<SignatureData>(account_addr);
        let message_hash = hash::sha3_256(message);
        
        // Check if message hash matches
        if (sig_data.message_hash != message_hash) {
            return false
        };

        // Verify the signature using ed25519
        let public_key = ed25519::new_unvalidated_public_key_from_bytes(sig_data.public_key);
        let signature = ed25519::new_signature_from_bytes(sig_data.signature);
        
        ed25519::signature_verify_strict(&signature, &public_key, message_hash)
    }
}