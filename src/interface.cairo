%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace EthVerifier {
    func write_confirmation(starknet_id, eth_address, signature_len: felt, signature: felt*) {
    }
}
