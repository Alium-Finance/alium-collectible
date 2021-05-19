pragma solidity =0.6.2;

contract Receiver {
    function callIt(address dest) public {
        ITransceiver(dest).freeze(address(1), 1, 1);
    }
}