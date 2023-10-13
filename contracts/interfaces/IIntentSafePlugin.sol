// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.18;

import '../common/Enum.sol';
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";

/// @title DSN Intent module interface
/// @dev DSn developers

interface IDSNIntentModule {

    enum ATOOperation {
        SWAP,
        BRIDGE,
        STAKE,
        SEND,
        UNSTAKE,
        WITHDRAW
    }

    /// @dev struct to store ATO information
    struct ATO {
        ATOOperation Operation;
        bytes fieldsToOptimize;
        bytes fieldsToOptimizeSchema;
        uint256 chainId;
        bytes payload;
        bytes payloadSchema;
        address sender;
    }

    /// @dev UserIntent object to capture intent from user
    struct UserIntent {
        address sender;
        ATO[] intent;
        uint256 nonce;
    }
    
    /// @dev Emitted when stake or unstake delay are modified.
    event FeePaid(
        bytes32 atoHash,
        uint256 fee
    );

    /// @dev Emitted once a stake by a solver is scheduled for withdrawal
    event ATOBroadcast(address indexed _account, ATO[] indexed _intent);

    /// @dev pay fees and broadcasts an ATO to the network
    /// @param _userSafeAccount - account of the user, ato - ATO to be solved
    /// @return success - true if fess paid and ATO broadcasted successfully
    function payFeesAndExecuteIntent(ISafeProtocolManager _manager, ISafe _userSafeAccount, UserIntent calldata _userIntent) external returns (bool);
        // ISafeProtocolManager manager, 
        // ISafe userSafeAccount,
        // ATO calldata ato
}