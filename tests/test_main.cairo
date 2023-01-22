%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starknetid.src.ISTarknetID import IStarknetid
from src.interface import EthVerifier

@external
func __setup__() {
    %{
        from starkware.starknet.compiler.compile import get_selector_from_name
        context.starknet_id_contract = deploy_contract("./lib/starknetid/src/StarknetId.cairo").contract_address
        context.eth_verifier_contract = deploy_contract("./src/main.cairo", [context.starknet_id_contract]).contract_address
    %}
    return ();
}

@external
func test_signature_works{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar starknet_id_contract;
    tempvar eth_verifier_contract;

    %{
        ids.starknet_id_contract = context.starknet_id_contract
        ids.eth_verifier_contract = context.eth_verifier_contract
        stop_prank_callable = start_prank(456, context.eth_verifier_contract)
    %}

    IStarknetid.mint(starknet_id_contract, 1);

    %{ to_sign = 465433259830703938800703765735784821238212665787606080952419111053597831998; %}
    // todo:
    // EthVerifier.write_confirmation(eth_verifier_contract, 2, 0x123, 1, new (123));

    return ();
}

@external
func test_invalid_signature{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar starknet_id_contract;
    tempvar eth_verifier_contract;
    %{
        ids.starknet_id_contract = context.starknet_id_contract
        ids.eth_verifier_contract = context.eth_verifier_contract
        expect_revert(error_message="Invalid ethereum signature")
    %}

    let starknet_id = 1;
    IStarknetid.mint(starknet_id_contract, starknet_id);
    EthVerifier.write_confirmation(eth_verifier_contract, starknet_id, 0x123, 1, new (123));

    return ();
}

@external
func test_not_owned_starknet_id{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar starknet_id_contract;
    tempvar eth_verifier_contract;

    %{
        ids.starknet_id_contract = context.starknet_id_contract
        ids.eth_verifier_contract = context.eth_verifier_contract
        expect_revert(error_message="You need to own the starkne_id you want to write to")
        stop_prank_callable = start_prank(456, context.eth_verifier_contract)
    %}

    IStarknetid.mint(starknet_id_contract, 2);
    %{
        stop_prank_callable()
        stop_prank_callable = start_prank(789, context.eth_verifier_contract)
    %}
    IStarknetid.mint(starknet_id_contract, 1);
    EthVerifier.write_confirmation(eth_verifier_contract, 2, 0x123, 1, new (123));

    return ();
}
