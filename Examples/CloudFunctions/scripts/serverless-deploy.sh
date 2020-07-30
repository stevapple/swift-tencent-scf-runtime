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
## Copyright (c) 2017-2018 Apple Inc. and the SwiftAWSLambdaRuntime project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See http://github.com/swift-server/swift-aws-lambda-runtime/blob/master/CONTRIBUTORS.txt
## for the list of SwiftAWSLambdaRuntime project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===------------------------------------------------------------------------------------===##

set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/config.sh

echo -e "\ndeploying $executable"

$DIR/build-and-package.sh "$executable"

echo "-------------------------------------------------------------------------"
echo "deploying using Serverless"
echo "-------------------------------------------------------------------------"

serverless deploy --config "./scripts/serverless/$executable-template.yml" --stage dev -v
