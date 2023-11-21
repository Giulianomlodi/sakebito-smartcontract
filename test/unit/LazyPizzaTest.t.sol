// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DeployLazyPizza} from "../../script/DeployLazyPizza.s.sol";
import {LazyPizza} from "../../src/LazyPizza.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

contract LazyPizzaTest is Test {}
