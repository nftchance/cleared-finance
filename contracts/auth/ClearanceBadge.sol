// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

/// @dev Contract shape definition.
import {IClearanceBadge} from "../interfaces/IClearanceBadge.sol";

/// @dev Core dependencies.
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Supporting libraries.
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ClearanceBadge is IClearanceBadge, ERC721Enumerable, Ownable {
    /// @dev Preparing the usage of signatures.
    using ECDSA for bytes32;

    /// @dev The address used to enable secure clearance minting.
    address public signer;

    /// @dev The number of seconds before expiration that a user may
    ///      re-establish their clearance as well as the base of the
    ///      minimum clearance duration.
    uint256 public gracePeriod;

    /// @dev The total number of ClearanceBadges minted.
    uint256 tokenId;

    /// @dev The nonces an address has used to mint a ClearanceBadge.
    mapping(address => uint256) public nonces;

    struct Clearance {
        uint48 activationDate;
        uint48 expirationDate;
    }

    mapping(uint256 => Clearance) public clearances;

    /// @dev Initialize the ClearanceBadge.
    constructor(
        string memory _name,
        string memory _symbol,
        address _signer
    ) ERC721(_name, _symbol) {
        /// @dev Prepare the signer for minting.
        _setSigner(_signer);
    }

    /**
     * See {IClearanceBadge-setSigner}.
     */
    function setSigner(address _signer) external onlyOwner {
        /// @dev Call the internal function for DRY signer management.
        _setSigner(_signer);
    }

    function mint(
        address _to,
        uint8 _nonce,
        uint48 _activationDate,
        uint48 _expirationDate,
        bytes calldata _signature
    ) external {
        /// @dev Build the message hashed as the base of the signature.
        /// @notice Includes `_msgSender()` to prevent bipartite minting.
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _msgSender(),
                _to,
                _nonce,
                _activationDate,
                _expirationDate
            )
        );

        /// @dev Recover the signer address from the signature.
        address recoveredSigner = messageHash.toEthSignedMessageHash().recover(
            _signature
        );

        /// @dev Ensure the recovered signer matches the stored signer.
        require(
            recoveredSigner == signer,
            "ClearanceBadge: invalid signature."
        );

        /// @dev Ensure the nonce is valid.
        /// @notice Included to prevent replay attacks and based
        ///         on `_msgSender()` to prevent DOS attacks.
        require(
            _nonce == nonces[_msgSender()]++,
            "ClearanceBadge: invalid signature nonce."
        );

        /// @dev Ensure the user does not already have a ClearanceBadge effective
        ///      for the time period of the new ClearanceBadge being minted.
        /// @notice Included to prevent overlapping access periods.
        require(
            balanceOf(_msgSender()) == 0 ||
                clearanceTimeRemaining(_msgSender()) <= gracePeriod,
            "ClearanceBadge: clearance cannot currently be provided."
        );

        /// @dev Confirm the duration period of the clearance is at least
        ///      as long as the grace period plus 1 day.
        /// @notice Included to prevent short duration clearances.
        require(
            _expirationDate - _activationDate >= gracePeriod + 1 days,
            "ClearanceBadge: clearance duration must be at least 1 day."
        );

        /// @dev Get the tokenId for the new ClearanceBadge.
        uint256 clearanceId = totalSupply();

        /// @dev Store the ClearanceBadge's activation date.
        clearances[clearanceId] = Clearance({
            activationDate: _activationDate,
            expirationDate: _expirationDate
        });

        /// @dev Mint the ClearanceBadge to the recipient.
        _safeMint(_to, clearanceId);
    }

    /**
     * See {IClearanceBadge-clearanceTimeRemaining}.
     */
    function clearanceTimeRemaining(
        address _account
    ) public view returns (uint256 balance) {
        /// @dev Initialize the balance.
        uint256 i = balanceOf(_account) - 1;
        uint256 clearanceId;
        uint256 expirationDate;

        /// @dev Iterate over the provided ClearanceBadges and confirm determine
        ///      the total time remaining.
        while (i >= 0) {
            /// @dev Get the ClearanceBadge's tokenId.
            clearanceId = tokenOfOwnerByIndex(_account, i);

            /// @dev Get the ClearanceBadge's expiration date.
            expirationDate = clearances[clearanceId].expirationDate;

            /// @dev If the ClearanceBadge is not active, skip it.
            if (expirationDate <= block.timestamp) {
                /// @dev Escape the loop because we've found active clearances.
                i = 0;
            }

            /// @dev If the ClearanceBadge is active, add the time remaining
            ///      to the balance and continue the loop.
            unchecked {
                /// @dev Calculate the time remaining with the difference.
                balance += expirationDate - block.timestamp;

                /// @dev Decrement the loop counter.
                i--;
            }
        }
    }

    /**
     * See {IClearanceBadge-clearanceTimeRemaining}.
     */
    function clearanceTimeRemaining(
        uint256 _tokenId
    ) external view returns (uint256 timeRemaining) {
        /// @dev Get the ClearanceBadge's expiration date.
        uint256 expirationDate = clearances[_tokenId].expirationDate;

        /// @dev If the ClearanceBadge is active, return the time remaining.
        if (expirationDate > block.timestamp)
            /// @dev Calculate the time remaining with the difference
            ///      in expiration and now.
            timeRemaining = expirationDate - block.timestamp;
    }

    /**
     * See {IClearanceBadge-setSigner}.
     */
    function _setSigner(address _signer) internal {
        /// @dev Update the stored signer address.
        signer = _signer;
    }
}
