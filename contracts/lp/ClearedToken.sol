// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Supporting interfaces.
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ClearedToken is ERC20 {
    /// @dev The Badge that is required in order to use the protocol.
    IERC721 public immutable clearanceBadge;

    /// @dev Initialize the ClearedToken.
    constructor(
        string memory _name,
        string memory _symbol,
        IERC721 _clearanceBadge
    ) ERC20(_name, _symbol) {
        /// @dev Store the reference to the access Badge.
        clearanceBadge = _clearanceBadge;
    }

    /**
     * @dev Confirm that a user has clearance to interact with the protocol before
     *      allowing them to receive any tokens to that address.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param amount The amount of tokens to transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        /// @dev Check the Badge balance of the recipient.
        require(
            clearanceBadge.balanceOf(to) > 0,
            "ClearedToken: recipient must have clearance badge."
        );

        /// @dev Continue with the normal checks.
        super._beforeTokenTransfer(from, to, amount);
    }
}
