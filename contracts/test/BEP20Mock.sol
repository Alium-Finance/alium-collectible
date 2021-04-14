pragma solidity =0.6.2;

import {
    ERC20Burnable,
    ERC20PresetMinterPauser
} from "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract BEP20Mock is ERC20PresetMinterPauser {
    constructor(string memory name, string memory symbol)
        public
        ERC20PresetMinterPauser(name, symbol)
    {}

    function burn(uint256 amount) public override(ERC20Burnable) {
        _burn(msg.sender, amount);
    }
}
