pragma solidity ^0.6.2;

interface ITransceiver {
    function freeze(
        address beneficiary,
        uint256 amount,
        uint8 vestingPlanId
    ) external returns (bool success);
}