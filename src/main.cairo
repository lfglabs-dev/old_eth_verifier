%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_secp.signature import (
    finalize_keccak,
    verify_eth_signature_uint256,
)
from starknetid.src.ISTarknetID import IStarknetid

@storage_var
func _starknetid_contract() -> (starknetid_contract: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    starknetid_contract
) {
    _starknetid_contract.write(starknetid_contract);
    return ();
}

@external
func write_confirmation{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(starknet_id, eth_address, signature_len: felt, signature: felt*) {
    // verify starknet id is owned by called
    let (caller) = get_caller_address();
    let (starknetid_contract) = _starknetid_contract.read();
    let (owner) = IStarknetid.owner_of(starknetid_contract, starknet_id);
    with_attr error_message("You need to own the starkne_id you want to write to") {
    assert caller = owner;
    }

    // verify eth_address is owned by caller
    let (hash) = hash2{hash_ptr=pedersen_ptr}('my starknetid is', starknet_id);
    with_attr error_message("Invalid ethereum signature") {
        check_eth_signature(eth_address, hash, signature_len, signature);
    }
    let (starknetid_contract) = _starknetid_contract.read();

    IStarknetid.set_verifier_data(starknetid_contract, starknet_id, 'eth_address', eth_address);
    return ();
}

func check_eth_signature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(eth_address, hash, signature_len: felt, signature: felt*) {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();

    // This interface expects a signature pointer and length to make
    // no assumption about signature validation schemes.
    // But this implementation does, and it expects a the sig_v, sig_r,
    // sig_s, and hash elements.
    let sig_v: felt = signature[0];
    let sig_r: Uint256 = Uint256(low=signature[1], high=signature[2]);
    let sig_s: Uint256 = Uint256(low=signature[3], high=signature[4]);
    let (high, low) = split_felt(hash);
    let msg_hash: Uint256 = Uint256(low=low, high=high);

    let (keccak_ptr: felt*) = alloc();
    local keccak_ptr_start: felt* = keccak_ptr;

    with keccak_ptr {
        verify_eth_signature_uint256(
            msg_hash=msg_hash, r=sig_r, s=sig_s, v=sig_v, eth_address=eth_address
        );
    }
    // Required to ensure sequencers cannot spoof validation check.
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr);
    return ();
}
