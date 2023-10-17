// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.18;

import '../common/Enum.sol';
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";

/// @title DSN Intent module interface

interface IDSNIntentModule {

    enum ATOOperation {
        SWAP,
        BRIDGE,
        STAKE
    }

    /// @dev struct to store ATO information
    struct ATO {
        ATOOperation Operation;
        uint256 minTokenIn; // how much token should be receive in min
        uint256 maxTokenIn; // upper limit for duction auction
        uint256 minTokenOut; // how much i can pay
        uint256 maxTokenOut; // how much more i am ready to pay
        address tokenInAddress;
        address tokenOutAddress;
        uint256 sourceChainId;
        uint256 destinationChainId;
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

    /// @dev pay fees
    /// @param _userSafeAccount - account of the user, ato - ATO to be solved
    /// @return success - true if fess paid and ATO broadcasted successfully
    function payFeesAndExecuteIntent(ISafeProtocolManager _manager, ISafe _userSafeAccount, UserIntent calldata _userIntent) external returns (bool);
        // ISafeProtocolManager manager, 
        // ISafe userSafeAccount,
        // ATO calldata ato
}