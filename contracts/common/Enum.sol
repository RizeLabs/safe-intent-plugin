// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.18;

/**
 * @title Enum - Collection of enums used in DSN module. 
 * @dev each supported operation has corresponding enum
 */

abstract contract Enum {

    enum Operation {
        DELEGATE_CALL,
        CALL
    }

    enum ModuleType {
        Plugin,
        Hooks,
        FunctionHandler
    }
}