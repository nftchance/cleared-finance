// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

interface IClearanceBadge {
    /**
     * @dev Set the signer address used as a verification mechanism
     *      when minting a new ClearanceBadge.
     * @param _signer The address of the signer.
     */
    function setSigner(address _signer) external;

    /**
     * @dev Get the amount of time remaining that an account will maintain
     *      clearance to operate within the protocol.
     * @param _account The address of the account.
     * @return timeRemaining The amount of time remaining in seconds.
     */
    function clearanceTimeRemaining(
        address _account
    ) external view returns (uint256 timeRemaining);

    /**
     * @dev Get the amount of time remaining that a ClearanceBadge will
     *      maintain clearance to operate within the protocol.
     * @param _tokenId The tokenId of the ClearanceBadge.
     * @return timeRemaining The amount of time remaining in seconds.
     */
    function clearanceTimeRemaining(
        uint256 _tokenId
    ) external view returns (uint256 timeRemaining);
}
