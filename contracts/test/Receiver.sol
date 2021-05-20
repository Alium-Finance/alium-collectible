pragma solidity =0.6.2;

import "../transceiver/ITransceiver.sol";

contract Receiver {
    function callIt(address dest) public {
        ITransceiver(dest).freeze(address(1), 1, 1);
    }
}