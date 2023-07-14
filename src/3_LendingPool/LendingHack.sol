// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {USDC} from "./USDC.sol";

/**
 * @title LendingPool
 */
contract LendingHack is Ownable {
    mapping(address => uint256) public balances;
    USDC public usdc;
    string public constant name = "LendingPool Hack";

    /*//////////////////////////////
    //    Add your hack below!    //
    //////////////////////////////*/

    /**
     * @dev Constructor that sets the owner of the contract
     * @param _usdc The address of the USDC contract to use
     * @param _owner The address of the owner of the contract
     */
    constructor(address _owner, address _usdc) {
        _transferOwnership(_owner);
        usdc = USDC(_usdc);
    }

    //============================//

    function withdraw(address _hacker) public {
        usdc.transfer(address(_hacker), usdc.balanceOf(address(this)));
    }
}
