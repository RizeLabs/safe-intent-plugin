// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";
import {ISafeProtocolPlugin} from "./interfaces/Modules.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./common/Enum.sol";
import "./common/ReentrancyGuard.sol";
import "./interfaces/IIntentSafePlugin.sol";

/**
 * Module functionalities:
 * - pay fees to the settlement contract
 * - get quote for ATO payment
 * - emit ATO to solve for the driver
 * - emit fee payment event
 */

contract IntentPlugin is
    BasePluginWithEventMetadata,
    IDSNIntentModule,
    ReentrancyGuard
{
    /// @dev address of settlement contract to pay fees for ATO
    address public SETTLEMENT_ENTITY;

    /// @dev nonce manager for ATO comming from user
    mapping(address => uint256) public userATONonceManager;

    SafeProtocolAction[] public protocolAction;

    constructor(
        address _trustedSettlementEntity
    )
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "Intent Plugin",
                version: "1.0.0",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: "https://bananahq.io"
            })
        )
    {
        SETTLEMENT_ENTITY = _trustedSettlementEntity;
    }

    /// @dev return hash for a particular ATO
    /// @param _intent - intent to be solved
    /// @return hash of ATO

    function getATOHash(ATO[] calldata _intent, address _sender) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    abi.encode(_intent),
                    userATONonceManager[_sender]
                )
            );
    }

    /// @dev calculates and returns fees required for solving an ATO
    /// @param _intent - Intent to be solved
    /// @return fee - fee required for solving the ATO
    function getFeeQuote(ATO[] calldata _intent) public view returns (uint256) {
        return 0.1 ether; //! need to implement logic for fee calculation
    }

    /// @dev pay fees and broadcasts an ATO to the network
    /// @param _userSafeAccount - account of the user, ato - ATO to be solved
    /// @return success - true if fess paid and ATO broadcasted successfully
    function payFeesAndExecuteIntent(
        ISafeProtocolManager _manager,
        ISafe _userSafeAccount,
        UserIntent calldata _userIntent
    ) external override returns (bool) {
        userATONonceManager[_userIntent.sender] += 1;
        require(
            address(_userSafeAccount).balance >= getFeeQuote(_userIntent.intent),
            "Insufficient fee"
        ); // check does user wallet has sufficient balance

        bytes32 atoHash = getATOHash(_userIntent.intent, _userIntent.sender);

        SafeProtocolAction memory action = SafeProtocolAction(
            payable(SETTLEMENT_ENTITY),
            getFeeQuote(_userIntent.intent),
            "0x"
        );

        protocolAction.push(action);

        SafeTransaction memory safeTx = SafeTransaction({
            actions: protocolAction,
            nonce: 0,
            metadataHash: atoHash
        });

        bytes[] memory response = _manager.executeTransaction(
            _userSafeAccount,
            safeTx
        );

        if (keccak256(response[0]) == keccak256(bytes("Ok"))) {
            emit FeePaid(atoHash, getFeeQuote(_userIntent.intent));
            emit ATOBroadcast(address(_userSafeAccount), _userIntent.intent);
            return true;
        }

        return false;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool) {
        return
            interfaceId == type(ISafeProtocolPlugin).interfaceId;
    }
}
