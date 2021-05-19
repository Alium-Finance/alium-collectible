pragma solidity =0.6.2;

contract Transmitter {

    bool public accepted = false;

    function freeze(
        address beneficiary,
        uint256 amount,
        uint8 vestingPlanId
    ) external returns (bool) {
        accepted = true;
        return accepted;
    }
}