from brownie import(
    network, 
    config, 
    accounts, 
    VRFCoordinatorV2Mock, 
    MockV3Aggregator, 
    Contract, 
    LinkToken,
    interface
)

from web3 import Web3

LOCAL_BLOCKCHAIN_ENVIRONMENTS = ['development', 'ganache-local']
FORKED_LOCAL_ENVIRONMENTS = ['mainnet-fork', 'mainnet-fork-dev']

DECIMALS = 8
STARTING_PRICE = 200000000000

def get_account(index=None, id=None):

    if index:
        return accounts[index]
    if id: 
        return accounts.load(id)

    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS 
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):
        return accounts[0]
    
    return accounts.add(config['wallets']['from_key'])


def deploy_mocks(decimals=DECIMALS, initial_value=STARTING_PRICE):
    account = get_account()
    print(f"The active network is {network.show_active()}")
    print("Deploying mocks ... ")
    MockV3Aggregator.deploy(decimals, initial_value, {'from': account})
    LinkToken.deploy({'from': account})
    VRFCoordinatorV2Mock.deploy(0, 0, {'from':account})
    print("Mock deployed")


contract_to_mock = {
    'eth_usd_price_feed' : MockV3Aggregator,
    'vrf_coordinator' : VRFCoordinatorV2Mock,
    'link_token': LinkToken
}

def get_contract(contract_name):

    """This function will grab the contract addresses from brownie config
    if defined, otherwise it will deploy a mock version of that contract, 
    and return that mock contract.

        Args:
            contract_name (string)

        Returns:
            brownie.network.contract.ProjectContract: the most recently
            deployed version of the contract.
    """

    contract_type = contract_to_mock[contract_name]
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        if len(contract_type) <= 0:
            deploy_mocks()

        contract = contract_type[-1]
    else:
        contract_address = config['networks'][network.show_active()][contract_name]
        contract = Contract.from_abi(
            contract_type._name, 
            contract_address, 
            contract_type.abi
        )
    
    return contract

def fund_with_link(contract_address, account=None, link_token=None, amount=5000000000000000000):
    account = account if account else get_account()
    
    # Two different ways of funding contract
    # 1. using mock LinkToken contract and making transfer  call
    link = link_token if link_token else get_contract('link_token')
    tx = link.transfer(contract_address, amount, {'from': account})
    
    # 2. Generating link token contract from interface
    #link_token_contract = interface.LinkTokenInterface(link.address)
    #tx2 = link_token_contract.transfer(contract_address, amount, {'from': account})

    tx.wait(1)
    print("Funded Contract !")
    return tx