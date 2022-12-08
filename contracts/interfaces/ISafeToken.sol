// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title  ISafeToken
/// @author crypt0grapher
/// @notice This contract is used as a token
interface ISafeToken is IERC20, IERC20Metadata {

    //buy a Safe Yields token for _amount in BUSD
    function buy(uint256 _amount) external payable;

    function mint(address usr, uint256 wad) external;

    function burn(address usr, uint256 wad) external;
}
