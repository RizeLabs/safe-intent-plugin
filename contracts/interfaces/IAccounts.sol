// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {Enum} from '../common/Enum.sol';
/**
 * @title IAccount Declares the functions that are called on an account by Safe{Core} Protocol.
 */
interface IAccount {
    function execTransactionFromModule(
        address payable to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);
}
