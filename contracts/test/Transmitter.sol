pragma solidity =0.6.2;

import "../transceiver/ITransceiver.sol";

contract Transmitter is ITransceiver {

    bool public accepted = false;

    event Accepted(address beneficiary, uint256 amount, uint8 vestingPlanId);

    function freeze(
        address beneficiary,
        uint256 amount,
        uint8 vestingPlanId
    ) external override returns (bool) {
        accepted = true;
        emit Accepted(beneficiary, amount, vestingPlanId);
        return accepted;
    }
}