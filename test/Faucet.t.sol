// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {Test} from "forge-std/Test.sol";

import {IFaucet} from "src/IFaucet.sol";
import {Faucet} from "src/Faucet.sol";

// Properties:
// * only one withdrawal per day per user
// * withdraw amount <= MAX_WITHDRAWAL
// * address(this).balance < withdraw_amount
// * can receive any amount > 0
// * cannot receive 0 ether

contract TestFaucet is Test {
    uint256 BLOCKTIMESTAMP_START = 0x1641070800;

    /// @dev
    IFaucet public faucetHuff;

    /// @dev
    IFaucet public faucet;

    address OWNER = vm.addr(0xaaa);

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    /// @dev Setup the testing environment.
    function setUp() public {
        // By default in foundry, the block.timestamp is uint256(1)
        // We set a radom block.timestamp
        vm.warp(BLOCKTIMESTAMP_START);

        vm.prank(OWNER);
        faucet = IFaucet(address(new Faucet()));
        vm.label(address(faucet), "Faucet");

        vm.prank(OWNER);
        faucetHuff = IFaucet(HuffDeployer.config().with_deployer(OWNER).deploy("Faucet"));
        vm.label(address(faucetHuff), "FaucetHuff");
    }

    function testFuzz_Receive(uint256 value) public {
        // This is a special case: it will be rejected by the contract
        // a specific test is done for this one
        vm.assume(value > 0);

        // give ether to the contract to send
        vm.deal(address(this), value);
        // Faucet
        vm.expectEmit(true, true, true, true, address(faucet));
        emit Deposit(address(this), value);
        (bool success, bytes memory data) = address(faucet).call{value: value}("");

        // give ether to the contract to send
        vm.deal(address(this), value);
        // FaucetHuff
        vm.expectEmit(true, true, true, true, address(faucetHuff));
        emit Deposit(address(this), value);
        (bool successHuff, bytes memory dataHuff) = address(faucetHuff).call{value: value}("");

        // compare results sol / huff success and data
        assertTrue(success, "call failed");
        assertEq(success, successHuff);
        assertEq(data, dataHuff);
    }

    function testCannotReceiveZeroEther() public {
        // Faucet
        vm.expectRevert(Faucet.DepositZero.selector);
        (bool success, bytes memory data) = address(faucet).call{value: 0}("");
        assertTrue(success, "expectRevert: call did not revert");

        // FaucetHuff
        vm.expectRevert(Faucet.DepositZero.selector);
        (bool successHuff, bytes memory dataHuff) = address(faucetHuff).call{value: 0}("");

        // compare results sol / huff
        assertTrue(success, "expectRevert: call did not revert");
        assertEq(success, successHuff);
        assertEq(data, dataHuff);
    }

    function testRevertOnFallbackWithoutMessage() public {
        // it will match the fallback
        bytes memory payload = bytes("random");

        // Faucet
        vm.expectRevert(bytes(""));
        (bool success, bytes memory data) = address(faucet).call(payload);

        // FaucetHuff
        vm.expectRevert(bytes(""));
        (bool successHuff, bytes memory dataHuff) = address(faucetHuff).call(payload);

        // compare results sol / huff
        assertTrue(success, "expectRevert: call did not revert");
        assertEq(success, successHuff);
        assertEq(data, dataHuff);
    }

    function testFuzz_CannotWithdrawIfAmountExceedMax(uint256 value) public {
        value = bound(value, faucet.MAX_WITHDRAWAL() + 0x01, type(uint256).max);

        // Users
        address user1 = vm.addr(0x123);
        vm.startPrank(user1);

        // Faucet
        vm.expectRevert(abi.encodeWithSelector(Faucet.ExceedMaxWithdrawalAmount.selector, value));
        faucet.withdraw(value);

        // FaucetHuff
        vm.expectRevert(abi.encodeWithSelector(Faucet.ExceedMaxWithdrawalAmount.selector, value));
        faucetHuff.withdraw(value);
    }

    function testFuzz_CannotWithdrawIfInsufficientBalanceFaucet(uint256 value) public {
        value = bound(value, 0x01, faucet.MAX_WITHDRAWAL());

        // Users
        address user1 = vm.addr(0x123);
        vm.startPrank(user1);

        // Faucet
        vm.expectRevert(abi.encodeWithSelector(Faucet.InsufficientBalanceFaucet.selector, value));
        faucet.withdraw(value);

        // FaucetHuff
        vm.expectRevert(abi.encodeWithSelector(Faucet.InsufficientBalanceFaucet.selector, value));
        faucetHuff.withdraw(value);
    }

    function testFuzz_CannotWithdrawMoreThanOnceADay(uint256 value) public {
        vm.assume(value > 0);

        // deal ether to faucets
        vm.deal(address(faucet), 10 ether);
        vm.deal(address(faucetHuff), 10 ether);
        vm.assume(value <= faucet.MAX_WITHDRAWAL());

        // Users
        address user1 = vm.addr(0x123);
        address user2 = vm.addr(0x456);

        // Faucet
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true, address(faucet));
        emit Withdrawal(user1, value);
        faucet.withdraw(value);
        assertEq(user1.balance, value);
        vm.expectRevert(Faucet.OneWithdrawalPerDay.selector);
        faucet.withdraw(value);
        assertEq(user1.balance, value);

        // FaucetHuff
        changePrank(user2);
        vm.expectEmit(true, true, true, true, address(faucetHuff));
        emit Withdrawal(user2, value);
        faucetHuff.withdraw(value);
        assertEq(user2.balance, value);
        vm.expectRevert(Faucet.OneWithdrawalPerDay.selector);
        faucetHuff.withdraw(value);
        assertEq(user2.balance, value);
    }

    function testFuzz_Withdraw(uint256 value) public {
        // deal ether to faucets
        vm.deal(address(faucet), 10 ether);
        vm.deal(address(faucetHuff), 10 ether);
        vm.assume(value <= faucet.MAX_WITHDRAWAL());

        // Users
        address user1 = vm.addr(0x123);
        address user2 = vm.addr(0x456);

        // Faucet
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true, address(faucet));
        emit Withdrawal(user1, value);
        faucet.withdraw(value);
        assertEq(user1.balance, value);

        // FaucetHuff
        changePrank(user2);
        vm.expectEmit(true, true, true, true, address(faucetHuff));
        emit Withdrawal(user2, value);
        faucetHuff.withdraw(value);
        assertEq(user2.balance, value);

        // advance a day
        // users should be able to withdraw again
        skip(86400);

        // Faucet
        changePrank(user1);
        vm.expectEmit(true, true, true, true, address(faucet));
        emit Withdrawal(user1, value);
        faucet.withdraw(value);
        assertEq(user1.balance, value * 2);

        // FaucetHuff
        changePrank(user2);
        vm.expectEmit(true, true, true, true, address(faucetHuff));
        emit Withdrawal(user2, value);
        faucetHuff.withdraw(value);
        assertEq(user2.balance, value * 2);
    }

    function testFuzz_AccountLastWithdrawal(uint256 value) public {
        value = bound(value, 0x01, faucet.MAX_WITHDRAWAL());

        // deal ether to faucets
        vm.deal(address(faucet), 10 ether);
        vm.deal(address(faucetHuff), 10 ether);

        // Users
        address user1 = vm.addr(0x123);
        address user2 = vm.addr(0x456);

        /// Verify last withdrawal before withdrawal
        // Faucet
        vm.startPrank(user1);
        uint256 lastWithdrawalUser1 = faucet.accountLastWithdrawal(user1);
        assertEq(lastWithdrawalUser1, 0);
        changePrank(user2);
        uint256 lastWithdrawalUser2 = faucet.accountLastWithdrawal(user2);
        assertEq(lastWithdrawalUser2, 0);

        // FaucetHuff
        changePrank(user1);
        lastWithdrawalUser1 = faucetHuff.accountLastWithdrawal(user1);
        assertEq(lastWithdrawalUser1, 0);
        changePrank(user2);
        lastWithdrawalUser2 = faucetHuff.accountLastWithdrawal(user2);
        assertEq(lastWithdrawalUser2, 0);

        /// Withdraw
        // Faucet
        changePrank(user1);
        vm.expectEmit(true, true, true, true, address(faucet));
        emit Withdrawal(user1, value);
        faucet.withdraw(value);
        assertEq(user1.balance, value);

        // FaucetHuff
        vm.expectEmit(true, true, true, true, address(faucetHuff));
        emit Withdrawal(user1, value);
        faucetHuff.withdraw(value);
        assertEq(user1.balance, value * 2);

        /// Verify last withdrawal after withdrawal
        // Faucet
        lastWithdrawalUser1 = faucet.accountLastWithdrawal(user1);
        assertEq(lastWithdrawalUser1, BLOCKTIMESTAMP_START);
        changePrank(user2);
        lastWithdrawalUser2 = faucet.accountLastWithdrawal(user2);
        assertEq(lastWithdrawalUser2, 0);

        // FaucetHuff
        changePrank(user1);
        lastWithdrawalUser1 = faucetHuff.accountLastWithdrawal(user1);
        assertEq(lastWithdrawalUser1, BLOCKTIMESTAMP_START);
        changePrank(user2);
        lastWithdrawalUser2 = faucetHuff.accountLastWithdrawal(user2);
        assertEq(lastWithdrawalUser2, 0);
    }

    /// @dev The current testing contract does not have a fallback
    ///      hence the transfer of eth will fail
    function testFuzz_RevertOnFailedEthTransfer(uint256 value) public {
        value = bound(value, 0x01, faucet.MAX_WITHDRAWAL());

        // deal ether to faucets
        vm.deal(address(faucet), 10 ether);
        vm.deal(address(faucetHuff), 10 ether);

        // Faucet
        vm.expectRevert(Faucet.EthTransferFailed.selector);
        faucet.withdraw(value);

        // FaucetHuff
        vm.expectRevert(Faucet.EthTransferFailed.selector);
        faucetHuff.withdraw(value);
    }

    function testFuzz_ChangeName(bytes32 newName) public {
        vm.startPrank(OWNER);

        // Faucet
        assertEq(faucet.name(), "Faucet");
        faucet.changeName(newName);
        assertEq(faucet.name(), newName);

        // FaucetHuff
        assertEq(faucetHuff.name(), "Faucet");
        faucetHuff.changeName(newName);
        assertEq(faucetHuff.name(), newName);
    }

    function testFuzz_CannotChangeNameIfNotOwner(bytes32 newName) public {
        // Faucet
        vm.expectRevert(abi.encodeWithSelector(Faucet.NotOwner.selector, address(this)));
        faucet.changeName(newName);

        // FaucetHuff
        vm.expectRevert(abi.encodeWithSelector(Faucet.NotOwner.selector, address(this)));
        faucetHuff.changeName(newName);
    }

    function testOwner() public {
        // Faucet
        assertEq(faucet.owner(), OWNER);

        // FaucetHuff
        assertEq(faucetHuff.owner(), OWNER);
    }
}
