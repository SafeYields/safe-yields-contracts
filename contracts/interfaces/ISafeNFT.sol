// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
//  ____         __       __   ___      _     _
//  /___|  __ _ / _| ___  \ \ / (_) ___| | __| |___
// \___ \ / _` | |_ / _ \  \ V /| |/ _ \ |/ _` / __|
//  ___) | (_| |  _|  __/   | | | |  __/ | (_| \__ \
// |____/ \__,_|_|  \___|   |_| |_|\___|_|\__,_|___/

/// @title  ISafeVault
/// @author crypt0grapher
/// @notice Safe Yield Vault depositing to the third-party yield farms
interface ISafeNFT is IERC1155 {
    enum Tiers {Tier1, Tier2, Tier3, Tier4}

    /**
    *   @notice purchase Safe NFT for exact amount of USD
    *   @param _tier tier of the NFT to purchase which stands for ERC1155 token id [0..3]
    *   @param _amount amount of USD to spend
    */
    function buy(Tiers _tier, uint256 _amount) external;

    /**
    *   @notice distribute profit among the NFT holders, the function fixes the amount of the reward and the NFT holders and their shares at the moment of the call. It does not transfer the reward to the NFT holders, it just records the amount of the reward for each NFT holder.
    *   @param _amountUSD amount of USD to distribute
    */
    function distributeProfit(uint256 _amountUSD) external;

    /**
    *   @notice the function calculates the amount of the reward for the NFT holder and transfers it to the NFT holder
    */
    function claimReward(Tiers _tier, uint256 _distributionId) external;

    /**
*   @notice the function calculates the amount of the reward for the NFT holder and transfers it to the NFT holder
    */
    function claimRewardsTotal() external;


    /**
    *   @notice gets NFT price for all tiers in USD
    */
    function getFairPriceTable() external returns (uint256[] memory);


    /**
    *   @notice gets NFT price in USD
    *   @return returns Rewards set for distribution
    */
    function getPrice(Tiers _tier) external returns (uint256);


    /**
    *   @notice gets NFT fair price in USD
    *   @return counts not only the sale price but also share of the profit for the tier
    */
    function getFairPrice(Tiers _tier) external returns (uint256);

    /**
    *   @notice gets the current distribution number
    *   @return current distribution number, the one that assigned to the latest distribution
    */
    function currentDistributionId() external returns (uint256);

    /**
    *   @notice undistributed profit amount in USD
    *   @return amount of the rewards not yet distributed to NFT holders
    */
    function getUnclaimedRewards() external returns (uint256);


    /**
    *   @notice returns the amount of the reward share for the NFT holder
    */
    function getMyPendingRewardsTotal() external returns (uint256);

    /**
    *   @notice returns the amount of the reward share for the NFT holder
    */
    function getPendingRewards(address _user, Tiers _tier, uint256 _distributionId)  external returns (uint256);

    /**
    *   @notice gets the total usd value of the NFT minted
    */
    function getTreasuryCost() external returns (uint256);
    /**
    *   @notice **Your NFTs (% Treasury) **is calculated in $ as a relation of total price of NFTs possessed by the $ amount of Investment Pool - including its SAFE and BUSD components.
    */
    function getMyShareOfTreasury() external returns (uint256);

}
