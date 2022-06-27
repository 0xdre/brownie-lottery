// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";



contract Lottery is Ownable, VRFConsumerBaseV2 {
    
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    address payable[] public players;
    address payable public recentWinner;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN, 
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;

    // 0: OPEN
    // 1: CLOSED
    // 2: CALCULATING_WINNER

    uint64 s_subscriptionId;
    bytes32 public keyhash;
    uint256[] public s_randomWords;
    uint256 public s_requestId;


    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

    event RequestedRandomness(bytes32 requestId);



    constructor(
        address _priceFeedAddress, 
        uint64 _s_subscriptionId,
        address _vrfCoordinator, 
        bytes32 _keyhash, 
        address _link_token_contract
        ) public VRFConsumerBaseV2(_vrfCoordinator) {
        
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        

        keyhash = _keyhash;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        COORDINATOR.addConsumer(_s_subscriptionId, address(this));
        LINKTOKEN = LinkTokenInterface(_link_token_contract);

        s_subscriptionId = _s_subscriptionId;

        // createNewSubscription();

        // COORDINATOR.addConsumer(s_subscriptionId, address(this));

    }

    // function addConsumer(address consumerAddress) external onlyOwner {
    //     // Add a consumer contract to the subscription.
    //     COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    // }

    // // Create a new subscription when the contract is initially deployed.
    // function createNewSubscription() private onlyOwner {
    //     s_subscriptionId = COORDINATOR.createSubscription();
    //     // Add this contract as a consumer of its own subscription.
    //     COORDINATOR.addConsumer(s_subscriptionId, address(this));
    // }


    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough EFFFF");
        players.push(payable(msg.sender));  
    }


    function getEntranceFee() public view returns(uint256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethUsdPriceFeed.latestRoundData();

        uint256 u_price = uint256(price) * 10**10; // changing to 18 decimals

        return (usdEntryFee * 10**18 / u_price);
    }


    function startLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Cant start a new lottery yet");
        lottery_state = LOTTERY_STATE.OPEN;
    }

    // function requestRandomWords() external onlyOwner {
    //     s_requestId = COORDINATOR.requestRandomWords(
    //         keyhash,
    //         s_subscriptionId, 
    //         requestConfirmations, 
    //         callbackGasLimit, 
    //         numWords
    //     );
    // }


    function endLottery() public onlyOwner {
        // generating pseudo random number based on global variables

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

        emit RequestedRandomness(s_requestId);

        uint256 indexOfWinner = uint256(
            keccak256(
                abi.encodePacked(
                    uint256(12), // nonce is predictable (aka tx number)
                    msg.sender, // predictable
                    block.difficulty, // can be manipulated my miners
                    block.timestamp // predicatble 
                )
            )
        ) % players.length;

        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        // s_requestId = COORDINATOR.requestRandomWords(
        //     keyhash,
        //     s_subscriptionId, 
        //     requestConfirmations, 
        //     callbackGasLimit, 
        //     numWords
        // );

        // Reset Loterry

        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }


    function fulfillRandomWords(
        uint256, 
        uint256[] memory randomWords
        ) internal override {
            require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, 'You arent there yet');
            s_randomWords = randomWords;

            uint256 indexOfWinner = s_randomWords[0] % players.length;
            recentWinner = players[indexOfWinner];
            recentWinner.transfer(address(this).balance);

            // Reset Loterry

            players = new address payable[](0);
            lottery_state = LOTTERY_STATE.CLOSED;
    }
}