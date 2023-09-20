// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";
import "./common/Enum.sol";
import "../common/ReentrancyGuard.sol";
import "./interfaces/IIntentSafePlugin.sol";

/**
 * Module functionalities:
 * - pay fees to the settlement contract
 * - get quote for ATO payment
 * - emit ATO to solve for the driver
 * - emit fee payment event
 */

contract IntentPlugin is BasePluginWithEventMetadata, IDSNIntentModule, ReentrancyGuard {
    
    /// @dev address of settlement contract to pay fees for ATO
    address public SETTLEMENT_ENTITY;

    /// @dev nonce manager for ATO comming from user
    mapping(address => uint256) public userATONonceManager;

    constructor(
        address _trustedSettlementEntity,
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
    /// @param ato - ATO struct
    /// @return hash of ATO

    function getATOHash(
        ATO calldata ato
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(abi.encode(ato), userATONonceManager[ato.sender])); 
    }

    /// @dev calculates and returns fees required for solving an ATO
    /// @param ato - ATO to be solved
    /// @return fee - fee required for solving the ATO
    function getFeeQuote(
        ATO calldata ato
    ) public view override returns (uint256) {
        return 0; //! need to figure out way to calculate fees for intent
    }

    /// @dev pay fees and broadcasts an ATO to the network
    /// @param userAccount - account of the user, ato - ATO to be solved
    /// @return success - true if fess paid and ATO broadcasted successfully
    function executeATO(
        ISafeProtocolManager manager, 
        ISafe userSafeAccount,
        ATO calldata ato
    ) external override returns (bool) {
        userATONonceManager[ato.sender] += 1;
        bytes32 atoHash = getATOHash(ato);
        require(msg.value >= getFeeQuote(ato), "Insufficient fee");
        //! contruct data for funding settlement contract via smart contract wallet 
        
        // construct fee payment transaction coded data for safe transaction
        bytes memory data = abi.encodeWithSelector(
            ISafe.executeTransaction.selector,
            SETTLEMENT_ENTITY,
            0,
            abi.encodeWithSelector(
                ISafe.fundContract.selector,
                SETTLEMENT_ENTITY,
                msg.value
            ),
            Enum.Operation.DELEGATE_CALL,
            0,
            0,
            0,
            address(0),
            address(0),
            ""
        );

        // construct safe transaction
        SafeTransaction memory tx = SafeTransaction({
            to: address(manager),
            value: 0,
            data: data,
            operation: SafeProtocolAction.CALL,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            nonce: 0
        });

        manager.executeTransaction(safe, safeTx);
        
        emit ATOBroadcast(address(safeAccount), ato);
        return true;
    }
}