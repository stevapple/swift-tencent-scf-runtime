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
workspace="$(pwd)/../.."

echo "-------------------------------------------------------------------------"
echo "Preparing docker build image"
echo "-------------------------------------------------------------------------"
docker build . -t builder
echo "done"

echo "-------------------------------------------------------------------------"
echo "Building \"$executable\" SCF"
echo "-------------------------------------------------------------------------"
docker run --rm -v "$workspace":/workspace -w /workspace/Examples/CloudFunctions builder \
       bash -cl "swift build --product $executable -c release -Xswiftc -static-executable"
echo "done"

echo "-------------------------------------------------------------------------"
echo "Packaging \"$executable\" SCF"
echo "-------------------------------------------------------------------------"
docker run --rm -v "$workspace":/workspace -w /workspace/Examples/CloudFunctions builder \
       bash -cl "./scripts/package.sh $executable"
echo "done"
