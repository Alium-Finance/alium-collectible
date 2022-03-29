pragma solidity =0.6.2;

import "../interfaces/IAliumVesting.sol";

contract MockVesting is IAliumVesting {
    event Frozen(
        address beneficiary,
        uint256 amount,
        uint8 vestingPlanId
    );

    function freeze(
        address beneficiary,
        uint256 amount,
        uint8 vestingPlanId
    )
        external
        override
        returns (bool success)
    {
        emit Frozen(
            beneficiary,
            amount,
            vestingPlanId
        );
        return true;
    }
}
