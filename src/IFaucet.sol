// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IFaucet {
    function accountLastWithdrawal(address account) external returns (uint256);
    function changeName(bytes32 name) external;
    function MAX_WITHDRAWAL() external returns (uint256);
    function name() external returns (bytes32);
    function owner() external returns (address);
    function withdraw(uint256 withdraw_amount) external;
}
