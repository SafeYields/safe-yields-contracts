// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./interfaces/ISafeToken.sol";
import "./interfaces/ISafeNFT.sol";
import "./interfaces/ISafeVault.sol";
import "./Wallets.sol";

/// @title  Safe NFT
/// @author crypt0grapher
/// @notice Safe Yields NFT token based on ERC1155 standard, id [0..3] represents one of the 4 tiers
contract SafeNFT is ISafeNFT, Wallets, ERC1155PresetMinterPauser, ERC1155Supply, Proxied, ReentrancyGuard {
    /// todo a number of tiers should be flexible
    uint256 public constant TIERS = 4;
    uint256 public constant WEEKS = 4;
    uint256[TIERS] public price;
    uint256[TIERS][WEEKS] public presalePrice;
    uint256[TIERS] public maxSupply;

    mapping(uint256 => string) private tokenURIs;
    address[] public tokenHolders;

    ISafeToken public safeToken;
    ISafeVault public safeVault;
    IERC20 public usd;
    string public constant name = "Safe Yields NFT";

    // @dev Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    uint256[WALLETS] public priceDistributionOnMint;
    uint256[WALLETS] public profitDistribution;
    uint256 public referralShareForNFTPurchase;
    address public preVaultWallet;

    // @dev Presale status, if true, only whitelisted addresses can mint
    bool public presale;
    // @dev Presale week for a tokenId, 0 means not in presale, user address => tier => presale week => amount
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public soldPerPresaleWeek;
    uint256[TIERS] public presaleMaxSupply;
    uint256[TIERS] public currentlySoldInPresale;

    mapping(address => bool) public isTokenHolder;

    // distribution ID, each distribution ID got an amount in USD and SAFE to distribute, snapshot of owned tokens, and snapshot of the total supply.
    uint256 public currentDistributionId;
    // @dev distributionId => total distribution amount in USD (total amount of USD sent for distribution)
    mapping(uint256 => uint256) public profitToDistribute;
    // @dev distributionId => SAFE to distribute to the holders (this is half of totalAmount in USD swapped for SAFE)
    mapping(uint256 => uint256) public safeToDistribute;
    // @dev distributionId => account => alreadyDistributedAmount (claimed)
    mapping(uint256 => mapping(address => uint256)) public alreadyDistributed;
    // @dev distributionId => tier => amount
    address public ambassador;
    // snapshot of the owned tokens on the moment of distribution
    // distributionId => address => tokens
    mapping(uint256 => mapping(address => uint256[TIERS])) public snapshotOfOwnedTokens;
    // distributionId => totalSupply
    mapping(uint256 => uint256[TIERS]) public snapshotOfTotalSupply;
    uint256 public discountedPrice;
    // @dev tier => amount
    mapping(uint256 => uint256) public soldInDiscountedSale;
    // @dev distributionId => already paid out amount in SafeToken
    mapping(uint256 => uint256) public alreadyDistributedTotal;


    event Sale(address indexed to, uint256 indexed id, uint256 indexed amount, uint256 price);

    /* ============ Modifiers ============ */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have admin role");
        _;
    }

    /* ============ External and Public State Changing Functions ============ */

    function initialize(string memory _uri, uint256[TIERS] memory _price, uint256[TIERS] memory _maxSupply, ISafeToken _safeToken, uint256[WALLETS] memory _priceDistributionOnMint, uint256 _referralShareForNFTPurchase, uint256[WALLETS] memory _profitDistribution, address _prevaultWallet) public proxied {
        _setURI(_uri);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        price = _price;
        maxSupply = _maxSupply;
        safeToken = _safeToken;
        priceDistributionOnMint = _priceDistributionOnMint;
        referralShareForNFTPurchase = _referralShareForNFTPurchase;
        profitDistribution = _profitDistribution;
        preVaultWallet = _prevaultWallet;
        _setWallets(safeToken.getWallets());
        safeVault = safeToken.safeVault();
        usd = safeToken.usd();
        usd.approve(address(safeToken), type(uint256).max);
        usd.approve(address(safeVault), type(uint256).max);
        safeToken.approve(address(safeToken), type(uint256).max);
        currentDistributionId = 0;
    }

    constructor(string memory _uri, uint256[TIERS] memory _price, uint256[TIERS] memory _maxSupply, ISafeToken _safeToken, uint256[WALLETS] memory _priceDistributionOnMint, uint256 _referralShareForNFTPurchase, uint256[WALLETS] memory _profitDistribution, address _prevaultWallet) ERC1155PresetMinterPauser(_uri) {
        initialize(_uri, _price, _maxSupply, _safeToken, _priceDistributionOnMint, _referralShareForNFTPurchase, _profitDistribution, _prevaultWallet);
    }

    //    ///TODO remove once filled with data
    //    function setOwnedTokenBatch(address[] calldata _owners, uint256[TIERS][] calldata _tokens) public onlyAdmin {
    //        require(_owners.length == _tokens.length, "Arrays must be of the same length");
    //        for (uint256 i = 0; i < _owners.length; i++) {
    //            ownedTokens[_owners[i]] = _tokens[i];
    //        }
    //    }


    function buy(Tiers _tier, uint256 _amount, address _referral) public nonReentrant {
        require(_amount > 0, "E RC1155PresetMinterPauser: amount must be greater than 0");
        ///todo check on totalsupply per tier
        require(price[uint256(_tier)] > 0, "ERC1155PresetMinterPauser: tier price must be greater than 0");
        bool referralExists = _referral != address(0);
        require(!referralExists || referralExists && _referral != _msgSender(), "Referral must be different from sender");
        uint256 id = uint256(_tier);

        //during presale the shares are distributed in USD, then in SAFE
        if (presale) {
            address sender = _msgSender();
            uint256 supplyLeft = presaleMaxSupply[uint256(_tier)] * 4 - currentlySoldInPresale[uint256(_tier)];
            require(_amount <= supplyLeft, "Maximum supply has been reached for the tier");
            soldInDiscountedSale[uint256(_tier)] += _amount;
            uint256 usdPrice = price[uint256(_tier)] * discountedPrice * _amount / HUNDRED_PERCENT;
            usd.transferFrom(_msgSender(), address(this), usdPrice);
            uint256 toSendToReferral = referralExists ? _transferPercent(usd, usdPrice, _referral, referralShareForNFTPurchase) : 0;
            uint256 toSendToAmbassador = !referralExists ? _transferPercent(usd, usdPrice, ambassador, referralShareForNFTPurchase) : 0;
            uint256 amountDistributed = _distribute(usd, usdPrice, priceDistributionOnMint);
            uint256 balance = usd.balanceOf(address(this));
            if (balance > 0) {
                usd.transfer(preVaultWallet, balance);
            }
            emit Sale(sender, _amount, uint256(_tier), usdPrice);
        }
        else {
            uint256 usdPrice = price[uint256(_tier)] * _amount;
            usd.transferFrom(_msgSender(), address(this), usdPrice);
            uint256 toSellForSafe = _getTotalShare(usdPrice, priceDistributionOnMint, referralExists ? referralShareForNFTPurchase : 0);
            uint256 safeAmount = safeToken.buySafeForExactAmountOfUSD(toSellForSafe);
            uint256 amountDistributed = _distribute(safeToken, safeAmount, priceDistributionOnMint);
            if (referralExists) {
                uint256 referralFee = _transferPercent(safeToken, safeAmount, _referral, referralShareForNFTPurchase);
                amountDistributed += referralFee;
            }
            uint256 balance = usd.balanceOf(address(this));
            if (balance > 0) {
                safeVault.deposit(balance);
            }
        }
        _mint(_msgSender(), id, _amount, "");
    }


    function distributeProfit(uint256 _amountUSD) public nonReentrant {
        usd.transferFrom(_msgSender(), address(this), _amountUSD);
        currentDistributionId++;
        profitToDistribute[currentDistributionId] = _amountUSD;
        uint256 rewardsToHolders = _amountUSD / 2;
        //send half to treasury and management
        uint256 distributedInternally = _distribute(usd, _amountUSD - rewardsToHolders, profitDistribution);
        // get snapshotOfOwnedTokens, loop through addresses, get tokens, and record distribution

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            address tokenHolder = tokenHolders[i];
            if (tokenHolder != address(0) && isTokenHolder[tokenHolder]) {
                for (uint256 j = 0; j < TIERS; j++) {
                    uint256 owned = balanceOf(tokenHolder, j);
                    if (owned > 0) {
                        snapshotOfOwnedTokens[currentDistributionId][tokenHolder][j] = owned;
                    }
                }
            }
        }
        // Now Selling Safe for USD in one transaction and setting it up for distribution
        safeToDistribute[currentDistributionId] = safeToken.buySafeForExactAmountOfUSD(rewardsToHolders);
        // Getting a snapshotOfTotalSupply
        snapshotOfTotalSupply[currentDistributionId] = getTotalSupplyAllTiers();
    }

    function claimReward() public nonReentrant {
        address user = _msgSender();
        for (uint256 distribution = currentDistributionId; distribution >= 0; distribution--) {
            uint256 reward = getPendingRewards(user, distribution);
            if (reward > 0) {
                usd.transfer(user, reward);
                alreadyDistributed[distribution][user] += reward;
                alreadyDistributedTotal[distribution] += reward;
            }
        }
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        // from part
        if (from != address(0)) {
            bool fromAddressIsNotATokenHolderAnymore = true;
            //proving this wrong, if the address still holds some tokens of any tier
            for (uint256 i = 0; i < ids.length; i++) {
                if (balanceOf(from, ids[i]) != 0) {
                    fromAddressIsNotATokenHolderAnymore = false;
                }
            }
            if (fromAddressIsNotATokenHolderAnymore) {
                isTokenHolder[from] = false;
            }
        }

        // to part
        if (to != address(0)) {
            // minting or transferring
            for (uint256 i = 0; i < ids.length; i++) {
                require(ids[i] < TIERS, "SafeNFT: wrong tier");
                if (!isTokenHolder[to]) {
                    tokenHolders.push(to);
                    isTokenHolder[to] = true;
                }
            }
        }

        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155PresetMinterPauser, ERC1155Supply) {
        if (from == address(0)) {
            //minting
            for (uint256 i = 0; i < ids.length; i++) {
                require(ids[i] < TIERS, "SafeNFT: wrong tier");
                require(totalSupply(ids[i]) <= maxSupply[ids[i]], "SafeNFT: max supply reached");
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155PresetMinterPauser, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /* ============ Admin  Functions ============ */

    function togglePresale() public onlyAdmin {
        presale = !presale;
        emit TogglePresale(presale);
    }


    function setPresaleMaxSupply(uint256[TIERS] memory _presaleMaxSupply) public onlyAdmin {
        presaleMaxSupply = _presaleMaxSupply;
    }

    function setAmbassador(address _ambassador) public onlyAdmin {
        ambassador = _ambassador;
    }

    function setDiscountedPrice(uint256 _discountedPrice) public onlyAdmin {
        discountedPrice = _discountedPrice;
    }

    function changePriceDistributionOnMint(uint256[WALLETS] memory _priceDistributionOnMint) public onlyAdmin {
        priceDistributionOnMint = _priceDistributionOnMint;
    }

    function setURI(uint256 _tokenId, string memory _tokenURI) public onlyAdmin {
        tokenURIs[_tokenId] = _tokenURI;
    }

    function burnAdmin(
        address account,
        uint256 id,
        uint256 value
    ) public onlyAdmin {
        _burn(account, id, value);
    }


    /* ============ External and Public View Functions ============ */

    function getNFTSupplyAvailable() public view returns (uint256[] memory) {
        uint256[] memory supplyLeft = new uint256[](TIERS);
        for (uint256 i = 0; i < TIERS; i++) {
            supplyLeft[i] = presaleMaxSupply[i] * 4 - currentlySoldInPresale[i] - soldInDiscountedSale[i];
        }
        return supplyLeft;
    }

    function getBalanceTable(address _user) public view returns (uint256[] memory) {
        uint256[] memory priceTable = new uint256[](TIERS);
        for (uint256 i = 0; i < TIERS; i++) {
            priceTable[i] = balanceOf(_user, i);
        }
        return priceTable;
    }


    function getMyBalanceTable() public view returns (uint256[] memory) {
        address user = _msgSender();
        return getBalanceTable(user);
    }

    function getPriceTable() public view returns (uint256[] memory) {
        uint256[] memory priceTable = new uint256[](TIERS);
        for (uint256 i = 0; i < TIERS; i++) {
            priceTable[i] = price[i];
        }
        return priceTable;
    }

    function getFairPriceTable() public view returns (uint256[] memory) {
        uint256[] memory priceTable = new uint256[](TIERS);
        for (uint256 i = 0; i < TIERS; i++) {
            priceTable[i] = getFairPrice(Tiers(i));
        }
        return priceTable;
    }

    function getPrice(Tiers _tier) public view returns (uint256) {
        return price[uint256(_tier)];
    }

    function getFairPrice(Tiers _tier) public view returns (uint256) {
        uint256 priceOfTier = price[uint256(_tier)];
        uint256 totalSupply = (totalSupply(uint256(_tier)) == 0 ? 1 : totalSupply(uint256(_tier)));
        uint256 profit = 0;
        for (uint256 i = 0; i < currentDistributionId; i++) {
            profit += profitToDistribute[i];
        }
        uint256 fairPrice = priceOfTier + profit * uint256(_tier) / totalSupply;
        return priceOfTier;
    }

    function getTotalSupplyAllTiers() public view returns (uint256[TIERS] memory) {
        uint256[TIERS] memory totalSupply_;
        for (uint256 i = 0; i < TIERS; i++) {
            totalSupply_[i] = totalSupply(i);
        }
        return totalSupply_;
    }

    function getMyPendingRewards() public view returns (uint256) {
        return getPendingRewards(_msgSender(), currentDistributionId);
    }

    function getPendingRewards(address _user, uint256 _distributionId) public view returns (uint256) {
        // user's rewards is the % of the total rewards for the tier
        uint256 weightedBalance = 0;
        for (uint256 tier = 0; tier < TIERS; tier++) {
            weightedBalance += balanceOf(_user, tier) * (tier + 1);
        }
        uint256 weightedSupply = 0;
        for (uint256 tier = 0; tier < TIERS; tier++) {
            weightedSupply += snapshotOfTotalSupply[_distributionId][tier] * (tier + 1);
        }

        uint256 rewards = weightedSupply == 0 ? 0 : safeToDistribute[_distributionId] * weightedBalance / weightedSupply;
        return rewards - alreadyDistributed[_distributionId][_user];
    }

    function getTreasuryCost() public view returns (uint256) {
        return usd.balanceOf(wallets[uint256(WalletsUsed.Treasury)]) + safeToken.balanceOf(wallets[uint256(WalletsUsed.Treasury)]) * safeToken.price() / 1e6;
    }

    function getMyShareOfTreasury() public view returns (uint256) {
        address user = _msgSender();
        uint treasuryShare = 0;
        for (uint256 tier = 0; tier < TIERS; tier++)
            treasuryShare += balanceOf(user, tier) * price[tier];
        uint256 treasuryCost = getTreasuryCost();
        return (treasuryCost == 0) ? 0 : treasuryShare * HUNDRED_PERCENT / treasuryCost;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory _tokenURI = tokenURIs[_tokenId];
        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(_tokenURI).length > 0 ? _tokenURI : super.uri(_tokenId);
    }

    function getUnclaimedRewards() public view returns (uint256) {
        uint256 unclaimedRewards = 0;
        for (uint256 distribution = currentDistributionId; distribution >= 0; distribution--) {
            unclaimedRewards += safeToDistribute[currentDistributionId] - alreadyDistributedTotal[currentDistributionId];
        }
        return unclaimedRewards;
    }

}
