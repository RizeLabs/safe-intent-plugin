// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {IAccount} from '../interfaces/IAccounts.sol';
import {Executor} from '../base/Executor.sol';
import {Enum} from '../common/Enum.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract SampleAccount is IAccount, Executor, Ownable {

    address public accountOwner;
    constructor(address _accountOwner) {
        accountOwner = _accountOwner;
    }

    function execTransactionFromModule(
        address payable to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external override returns (bool success) {
        success = Executor.execute(to, value, data, operation, type(uint256).max);   
        return success;
    }

    receive() external payable {}

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external override returns (bool success, bytes memory returnData) {
        success = Executor.execute(to, value, data, operation, type(uint256).max);   
        return (success, "Ok");
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) onlyOwner() external returns (bool success, bytes memory returnData) {
        success = Executor.execute(to, value, data, operation, type(uint256).max);   
        return (success, "Ok");
    }
}