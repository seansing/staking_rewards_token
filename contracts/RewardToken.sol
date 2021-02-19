// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

/// @title RewardToken.sol
/// @author Sean Sing
/// @dev RewardToken contract for Staker.sol

//inherit OpenZeppelin's ERC20 ccontract
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    using SafeMath for uint256;

    uint256 public tokenPrice;
    address public owner;

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }

    //@notice Initialize the RewardToken contract with an initial supply and token price
    //@param _initialSupply _tokenPrice  Initial token supply number and token price
    constructor(uint256 _initialSupply, uint256 _tokenPrice)
        public
        ERC20("Reward Token", "RTKN")
    {
        _mint(msg.sender, _initialSupply);
        tokenPrice = _tokenPrice;
        owner = msg.sender;
    }

    //@notice Method for owner to mint token.
    function mintToken(uint256 _amountToMint) public onlyOwner {
        _mint(msg.sender, _amountToMint);
    }
}
