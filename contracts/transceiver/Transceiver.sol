pragma solidity ^0.6.2;

import "./ITransceiver.sol";
import "./Roles.sol";
import "../IAliumVesting.sol";

// Set as freezer
contract Transceiver is ITransceiver, Roles {

    // address that we should call on type receive
    mapping (uint256 => address) private _dests;

    event Linked(uint256 typeId, address dest);

    function linkTypeToAddress(uint256 _typeId, address _dest) external onlyOwner {
        _dests[_typeId] = _dest;
        emit Linked(_typeId, _dest);
    }

    function freeze(
        address beneficiary,
        uint256 amount,
        uint8 vestingPlanId
    )
        external
        override
        onlyReceiver
        returns (bool success)
    {
        require(_dests[vestingPlanId] != address(0), "Transceiver: type not initialized");
        require(isTransmitter(_dests[vestingPlanId]), "Transceiver: transmitter not found");

        IAliumVesting(_dests[vestingPlanId]).freeze(beneficiary, amount, vestingPlanId);
        return true;
    }
}