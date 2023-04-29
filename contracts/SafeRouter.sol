/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISafeToken.sol";

contract SafeRouter is Proxied, ReentrancyGuard {
    address public kyberSwapRouterContract;
    ISafeToken public safeTokenContract;
    bytes4 public constant swap = 0xe21fd0e9;
    bytes4 public constant swapSimpleMode = 0x8af033fb;
    IERC20 public usd;


    function initialize(address _kyberSwapRouter, address _usd, address _safeToken) public proxied {
        kyberSwapRouterContract = _kyberSwapRouter;
        usd = IERC20(_usd);
        safeTokenContract = ISafeToken(_safeToken);
        usd.approve(address(safeTokenContract), type(uint256).max);
        safeTokenContract.approve(address(safeTokenContract), type(uint256).max);

    }

    constructor(address _kyberSwapRouter, address _usd, address _safeToken) {
        initialize(_kyberSwapRouter, _usd, _safeToken);
    }

    function approveTokens(
        address[] calldata tokens,
        address spender,
        uint256 amount
    ) external onlyProxyAdmin {
        uint256 tokenCount = tokens.length;
        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20 token = IERC20(tokens[i]);
            bool success = token.approve(spender, amount);
            require(success, "Token approval failed");
        }
    }

    function updateAllowedContract(address _allowedContract) external {
        require(msg.sender == tx.origin, "Only EOA can update the allowed contract");
        kyberSwapRouterContract = _allowedContract;
    }


    function proxyAndBuy(bytes calldata data) external nonReentrant {
        bytes4 functionSignature = extractFunctionSignature(data);
        require(functionSignature == swap || functionSignature == swapSimpleMode, "Not allowed function");
        (bool success, bytes memory returnData) = kyberSwapRouterContract.call(data);
        if (!success) {
            assembly {
                let returnDataSize := mload(returnData)
                revert(add(32, returnData), returnDataSize)
            }
        } else {
            (uint256 returnAmount, uint256 gasUsed) = abi.decode(returnData, (uint256, uint256));
            uint safeTokensToBuy = safeTokenContract.buySafeForExactAmountOfUSD(returnAmount);
            safeTokenContract.transfer(msg.sender, safeTokensToBuy);
        }
    }

    function sellAndProxy(bytes calldata data, uint256 safeAmount) external nonReentrant {
        bytes4 functionSignature = extractFunctionSignature(data);
        require(functionSignature == swap || functionSignature == swapSimpleMode, "Not allowed function");
        uint currentUSD = usd.balanceOf(address(this));
        uint usdToReturn = safeTokenContract.sellExactAmountOfSafe(safeAmount);
        (bool success, bytes memory returnData) = kyberSwapRouterContract.delegatecall(data);
        require(success, "KyberSwap execution failed");
        (uint256 returnAmount, uint256 gasUsed) = abi.decode(returnData, (uint256, uint256));
        uint remainingUsd = usd.balanceOf(address(this));
        if (remainingUsd > currentUSD) {
            usd.transfer(msg.sender, remainingUsd - currentUSD);
        }
    }

    function extractFunctionSignature(bytes memory data) internal pure returns (bytes4) {
        require(data.length >= 4, "Invalid data length");
        bytes4 signature;
        assembly {
            signature := mload(add(data, 32))
        }
        return signature;
    }
}
