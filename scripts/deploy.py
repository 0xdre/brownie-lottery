from brownie import Lottery, config, network
from scripts.helpers import get_account, get_contract, fund_with_link
import time

def deploy_lottery():

    account = get_account()

    print(account)

    Lottery.deploy(
        get_contract('eth_usd_price_feed').address, 
        7168,
        get_contract('vrf_coordinator').address, 
        config['networks'][network.show_active()]['key_hash'], 
        get_contract('link_token').address, 
        {'from': account}, 
        publish_source=config['networks'][network.show_active()].get('verify', False)
    )

    print("Deployed lottery!")


def start_lottery():
    account = get_account()
    lottery = Lottery[-1]
    starting_tx = lottery.startLottery({'from': account})
    starting_tx.wait(1)
    print("The lottery has started")

def enter_lottery():
    account = get_account()
    lottery = Lottery[-1]
    value = lottery.getEntranceFee() + 1000000
    tx = lottery.enter({'from': account, 'value': value})
    tx.wait(1)
    print('You entered the lottery!')

def end_lottery():
    account = get_account()
    lottery = Lottery[-1]

    fund_with_link(lottery.address)

    tx = lottery.endLottery({'from': account})
    tx.wait(1)
    time.sleep(60)
    print(f'{lottery.recentWinner()} is the new winner!')

def main():
    deploy_lottery()
    start_lottery()
    enter_lottery()
    end_lottery()
