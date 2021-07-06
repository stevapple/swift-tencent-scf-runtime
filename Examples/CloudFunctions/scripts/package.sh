#!/bin/bash
##===------------------------------------------------------------------------------------===##
##
## This source file is part of the SwiftTencentSCFRuntime open source project
##
## Copyright (c) 2020 stevapple and the SwiftTencentSCFRuntime project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftTencentSCFRuntime project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===------------------------------------------------------------------------------------===##
##
## This source file was part of the SwiftAWSLambdaRuntime open source project
##
## Copyright (c) 2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See http://github.com/swift-server/swift-aws-lambda-runtime/blob/main/CONTRIBUTORS.txt
## for the list of SwiftAWSLambdaRuntime project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===------------------------------------------------------------------------------------===##

set -eu

executable=$1

target=".build/scf/$executable"
rm -rf "$target"
mkdir -p "$target"

cp ".build/release/$executable" "$target/bootstrap"
ldd ".build/release/$executable" | grep swift | awk '{print $3}' | xargs cp -Lv -t "$target"

cd "$target"
zip ../$executable.zip *
