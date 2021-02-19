//SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/// @title Staker.sol
/// @author Sean Sing
/// @dev Staking contract for RewardToken.sol

//@notice contract to inherit RewardToken contract where tokens are minted and inherits Open Zeppelin's ERC20 standard.
import "./RewardToken.sol";

contract Staker is RewardToken {
    //@notice Contract is deployed with some tokens mindted for the distribution to stakers.
    constructor() public RewardToken(10000, 1) {}

    uint256 currentBlockNumber = block.number; //get current block time to ensure owner can only call reward after every block

    //@notice Method for an investor to purchase tokens for staking.
    function deposit() public payable {
        addInvestor(msg.sender);
        uint256 tokenToTransfer = msg.value / tokenPrice; //calculate how many tokens to transfer based on investment
        _transfer(owner, msg.sender, tokenToTransfer);
    }

    //@dev Track list of investors.
    address[] public investors;

    //@notice Method to check if address is a current investor.
    //@param _address The address to check if it is a current investor.
    function checkInvestor(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < investors.length; i += 1) {
            if (_address == investors[i]) return (true, i);
        }
        return (false, 0);
    }

    //@notice Method to check and add a new investor
    //@param _investor the investor to add.
    function addInvestor(address _investor) internal {
        (bool _checkInvestor, ) = checkInvestor(_investor);
        require(!_checkInvestor, "Already an investor.");
        investors.push(_investor);
    }

    //@notice Method to remove an investor
    //@param _investor the investor to remove.

    //Staking

    //@notice Track each investor's stake amount and total staked.
    mapping(address => uint256) public stakedAmount;
    uint256 public totalStaked;

    //@notice Method for an investor to stake his tokens.
    //@param _tokenToStake The amount of tokens the investor wants to stake.
    function stake(uint256 _tokenToStake) public {
        uint256 tokenBalance = balanceOf(msg.sender);
        require(
            tokenBalance > 0 && _tokenToStake <= tokenBalance,
            "No tokens are available or insufficient tokens to stake"
        );
        stakedAmount[msg.sender] = stakedAmount[msg.sender].add(_tokenToStake);
        _burn(msg.sender, _tokenToStake); //burn token amount used for staking
        totalStaked = totalStaked.add(_tokenToStake); //incraete total staked amount
    }

    //Rewards

    //@notice To track reward amount for an address
    mapping(address => uint256) public rewardAmount;

    //@notice Method for owner to reward staking pool at subsequent block number
    //@dev Owner to setup an automated call for this method, it checks that block number has increased from the current block
    //@dev replaces currentBlockNumber with new blockNumber and 100 tokens are being distributed to the pool.
    function rewardStakingPool() public onlyOwner {
        require(block.number > currentBlockNumber); //ensures reward can only be initiated every new block number
        currentBlockNumber = block.number;
        totalStaked = totalStaked.add(100);
        _burn(owner, 100);
        distributeReward(totalStaked);
    }

    //@dev Owner to setup an automated call for this method,
    //@notice Method for owner to distribute staking reward
    function distributeReward(uint256 _totalStaked) public onlyOwner {
        for (uint256 i = 0; i < investors.length; i += 1) {
            address currentInvestor = investors[i];
            rewardAmount[currentInvestor] = rewardAmount[currentInvestor].add(
                calculateReward(currentInvestor, _totalStaked)
            );
        }
    }

    //@notice Method for an investor to stake his tokens.
    //@param _investor The amount of tokens the investor wants to stake.
    //Total stakd tokens is divided by the total balance of the deposited tokens so each depositor get's proportional share of the rewards.
    function calculateReward(address _investor, uint256 _totalStaked)
        public
        view
        returns (uint256)
    {
        return _totalStaked.div(stakedAmount[_investor]);
    }

    //@notice Method for users to withdraw staking rewards and add to their token balance for full withdrawal (principal plus earned rewards).
    //@dev Safety feature: Mitigate re-entrancy attack by setting withdrawer's amount to 0 before minting.
    function withdraw() public {
        require(rewardAmount[msg.sender] > 0, "No rewards to withdraw.");
        uint256 rewardToWithdraw = rewardAmount[msg.sender];
        uint256 totalToWithdraw = balanceOf(msg.sender).add(rewardToWithdraw);
        rewardAmount[msg.sender] = 0; //sets balance to 0 first to avoid re-entrancy attack
        _mint(msg.sender, totalToWithdraw); //mints new token withdrawn, balance of withdrawer increased by ERC20 mint function.
    }

    //@notice Method for users to withdraw full amount of their tokens (principal plus earned rewards).
    function cashOut() public {
        require(balanceOf(msg.sender) > 0, "No tokens to withdraw.");
        uint256 amountToTransfer = balanceOf(msg.sender) / tokenPrice; //calculate token values in wei
        //_balances in ERC20 contract handles the balance of withdrawer.
        msg.sender.transfer(amountToTransfer);
        _burn(msg.sender, balanceOf(msg.sender)); //burn tokens after withdrawal
    }
}
