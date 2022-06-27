from brownie import Lottery, accounts, config, network
from web3 import Web3

# 50 USD ~= .041 ETH
# == 41000000000000000 wei

def test_get_entrance_fee():
    account = accounts[0]

    lottery = Lottery.deploy(
        config['networks'][network.show_active()]['eth_usd_price_feed'], 
        {'from': account}
    )

    assert lottery.getEntranceFee() > Web3.toWei(0.035, 'ether')
    assert lottery.getEntranceFee() < Web3.toWei(0.045, 'ether')