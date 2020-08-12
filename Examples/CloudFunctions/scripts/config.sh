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

DIR="$(cd "$(dirname "$0")" && pwd)"
executables=( $(swift package dump-package | sed -e 's|: null|: ""|g' | jq '.products[] | (select(.type.executable)) | .name' | sed -e 's|"||g') )

if [[ ${#executables[@]} = 0 ]]; then
    echo "No executables found"
    exit 1
elif [[ ${#executables[@]} = 1 ]]; then
    executable=${executables[0]}
elif [[ ${#executables[@]} > 1 ]]; then
    echo "Multiple executables found:"
    for executable in ${executables[@]}; do
      echo "  * $executable"
    done
    echo ""
    read -p "Select which executable to deploy: " executable
fi

echo "-------------------------------------------------------------------------"
echo "Configuration"
echo "-------------------------------------------------------------------------"
echo "current dir: $DIR"
echo "executable: $executable"
echo "-------------------------------------------------------------------------"
