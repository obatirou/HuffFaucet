// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IFaucet} from "src/IFaucet.sol";

contract Faucet is IFaucet {
    // Max withdrawal per account
    uint256 public constant MAX_WITHDRAWAL = 0.1 ether;
    // Owner of Faucet
    address public immutable owner;
    // Name of the contract (dummy only to use the onlyOwner modifier)
    bytes32 public name;
    // Account to last withdrawal
    mapping(address => uint256) public accountLastWithdrawal;

    // events
    event Withdrawal(address indexed to, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    // errors
    error NotOwner(address caller);
    error ExceedMaxWithdrawalAmount(uint256 amount);
    error InsufficientBalanceFaucet(uint256 amount);
    error OneWithdrawalPerDay();
    error DepositZero();
    error EthTransferFailed();

    constructor() {
        owner = msg.sender;
        name = bytes32("Faucet");
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    receive() external payable {
        if (msg.value == 0) {
            revert DepositZero();
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 withdraw_amount) public {

        if (withdraw_amount > MAX_WITHDRAWAL) {
            revert ExceedMaxWithdrawalAmount(withdraw_amount);
        }

        if (address(this).balance < withdraw_amount) {
            revert InsufficientBalanceFaucet(withdraw_amount);
        }

        if (accountLastWithdrawal[msg.sender] + 1 days > block.timestamp) {
            revert OneWithdrawalPerDay();
        }

        accountLastWithdrawal[msg.sender] = block.timestamp;
        (bool success,) = payable(msg.sender).call{value: withdraw_amount}("");
        if (!success) {
            revert EthTransferFailed();
        }
        emit Withdrawal(msg.sender, withdraw_amount);
    }

    function changeName(bytes32 newName) external onlyOwner {
        name = newName;
    }
}
