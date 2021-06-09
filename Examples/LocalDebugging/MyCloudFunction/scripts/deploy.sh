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

executable=MyCloudFunction
function_name=swift-sample
scf_region=ap-beijing
cos_bucket=swift-scf-test-<appid>
cos_region=ap-beijing

echo -e "\ndeploying $executable"

echo "-------------------------------------------------------------------------"
echo "Preparing docker build image"
echo "-------------------------------------------------------------------------"
docker build . -t builder
echo "done"

echo "-------------------------------------------------------------------------"
echo "Building \"$executable\" SCF"
echo "-------------------------------------------------------------------------"
docker run --rm -v `pwd`/../../..:/workspace -w /workspace/Examples/LocalDebugging/MyCloudFunction builder \
       bash -cl "swift build --product $executable -c release -Xswiftc -static-executable"
echo "done"

echo "-------------------------------------------------------------------------"
echo "Packaging \"$executable\" SCF"
echo "-------------------------------------------------------------------------"
docker run --rm -v `pwd`:/workspace -w /workspace builder \
       bash -cl "./scripts/package.sh $executable"
echo "done"

echo "-------------------------------------------------------------------------"
echo "Uploading \"$executable\" function to COS"
echo "-------------------------------------------------------------------------"
coscmd -b "$cos_bucket" -r "$cos_region" upload ".build/scf/$executable.zip" "$executable.zip"

echo "-------------------------------------------------------------------------"
echo "Updating \"$function_name\" to the latest \"$executable\""
echo "-------------------------------------------------------------------------"
tccli scf UpdateFunctionCode --region "$scf_region" \
       --FunctionName "$function_name" --Handler "swift.main" \
       --CodeSource "Cos" --CosBucketName "$cos_bucket" --CosBucketRegion "$cos_region" --CosObjectName "$executable.zip"
echo "done"
