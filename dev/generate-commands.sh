#!/bin/bash
##
## This source file is part of the valkey-swift project
## Copyright (c) 2025 the valkey-swift project authors
##
## See LICENSE.txt for license information
## SPDX-License-Identifier: Apache-2.0
##
swift run ValkeyCommandsBuilder
swift format format -ir Sources
