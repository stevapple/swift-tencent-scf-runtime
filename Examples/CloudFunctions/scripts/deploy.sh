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
## See http://github.com/swift-server/swift-aws-lambda-runtime/blob/master/CONTRIBUTORS.txt
## for the list of SwiftAWSLambdaRuntime project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===------------------------------------------------------------------------------------===##

set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/config.sh

workspace="$DIR/../.."

echo -e "\nDeploying $executable"

$DIR/build-and-package.sh "$executable"

echo "-------------------------------------------------------------------------"
echo "Uploading \"$executable\" function to COS"
echo "-------------------------------------------------------------------------"

read -p "COS bucket to upload (name-appid, eg: examplebucket-1250000000): " cos_bucket
cos_bucket=${cos_bucket:-swift-scf-test} # default for easy testing

read -p "COS bucket region (eg: ap-beijing): " cos_region
cos_region=${cos_region:-ap-beijing} # default for easy testing

coscmd -b "$cos_bucket" -r "$cos_region" upload ".build/scf/$executable/cloud-function.zip" "$executable.zip"

echo "-------------------------------------------------------------------------"
echo "Updating SCF function to use \"$executable\""
echo "-------------------------------------------------------------------------"

read -p "Cloud Function name (must exist in SCF): " function_name
function_name=${function_name:-SwiftSample} # default for easy testing

read -p "Cloud Function region (eg: na-toronto): " scf_region
scf_region=${scf_region:-na-toronto} # default for easy testing

tccli scf UpdateFunctionConfiguration --region "$scf_region" --FunctionName "$function_name" --Runtime "CustomRuntime" --InitTimeout 3
tccli scf UpdateFunctionCode --region "$scf_region" --FunctionName "$function_name" --Handler "swift.main" --CodeSource "Cos" --CosBucketName "$cos_bucket" --CosBucketRegion "$cos_region" --CosObjectName $executable.zip
