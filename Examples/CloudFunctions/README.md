# Serverless Cloud Functions Examples

This sample project is a collection of cloud functions that demonstrates how to write a simple SCF function in Swift, and how to package and deploy it to the Tencent SCF Platform.

The scripts are prepared to work from the `CloudFunctions` folder.

```
git clone https://github.com/stevapple/swift-tencent-scf-runtime.git
cd swift-tencent-scf-runtime/Examples/CloudFunctions
```

Note: The example scripts assume you have [jq](https://stedolan.github.io/jq/download/) command line tool installed. You're recommended to deploy with Serverless Framework in your own project.

FIXME: The `CurrencyExchange` example cannot be statically linked currently.

## Deployment instructions using TCCLI and COSCMD

Steps to deploy this sample to Tencent SCF Platform using TCCLI and COSCMD:

1. Prepare a COS bucket for keeping SCF packages
2. Login to SCF Console and create a cloud function
3. Build, package and deploy the function

```
./scripts/deploy.sh [executable]
```

You can combine step 2 and 3 with:

```
./scripts/create-and-deploy.sh [executable]
```

Notes: 
- This script assumes you have TCCLI installed and user configured (See https://cloud.tencent.com/document/product/440/34012).
- This script also assumes you have COSCMD installed and user configured with the same main account as the one in TCCLI (See https://cloud.tencent.com/document/product/436/10976).
- You'll be prompted to provide the COS bucket ID and region, and the SCF function name and region.
- The COS bucket must exist before deploying, as well as the SCF function if you use `deploy.sh`.

### Deployment instructions using Serverless Framework for Tencent (serverless.com/cn)

[Serverless framework](https://www.serverless.com/open-source/) (Serverless) is a provider agnostic, open-source framework for building serverless applications. [Serverless framework for Tencent](https://www.serverless.com/cn/) is a highly customized version that allows you to easily deploy other Tencent Cloud resources and more complex deployment mechanisms such a CI pipelines. Serverless Framework offers solutions for not only deploying but also testing, monitoring, alerting, and security and is widely adopted by the industry, and the Tencent Cloud version is totally free.

***Note:*** Deploying using Serverless will automatically create resources within your Tencent Cloud account. Charges may apply for these resources.

To use Serverless to deploy this sample to Tencent Cloud:

1. Install Serverless by following the [instructions](https://www.serverless.com/framework/docs/getting-started/). If you already have installed, be sure you have the latest version.

The examples have been tested with the version 1.80.0.

```
$ serverless --version
Framework Core: 1.80.0
Plugin: 3.8.0
SDK: 2.3.1
Components: 2.34.9
```

2. Build, package and deploy the cloud function

```
./scripts/serverless-deploy.sh [executable]
```

The script will ask you which sample function you wish to deploy if you don't provide one in the parameter.

3. Test

For the APIGateway sample, the Serverless template provides an endpoint with API Gateway which you can use to test the cloud function.

Output example:

```
$ ./scripts/serverless-deploy.sh APIGateway

serverless ⚡ framework
Action: "deploy" - Stage: "dev" - App: "SwiftAPIGatewayDemo" - Instance: "SwiftAPIGatewayDemo"

functionName: apigateway-swift-scf
description:  Swift SCF demo for APIGateway
namespace:    default
runtime:      CustomRuntime
handler:      swift.main
memorySize:   64
lastVersion:  $LATEST
traffic:      1
triggers:
  apigw:
    - http://service-jyl9i6mc-1258834142.bj.apigw.tencentcs.com/release/api

Full details: https://serverless.cloud.tencent.com/apps/SwiftAPIGatewayDemo/SwiftAPIGatewayDemo/dev

7s › SwiftAPIGatewayDemo › Success
```

Test command example:

```
curl http://service-jyl9i6mc-1258834142.bj.apigw.tencentcs.com/release/api
```

***Warning:*** This Serverless template is only intended as a sample and creates a publicly accessible HTTP endpoint.

For extensive usage, you need to customize `serverless.yml` yourself.

4. Remove

```
./scripts/serverless-remove.sh [executable]
```

The script will ask you which sample function you wish to remove from the previous deployment if you don't provide one in the parameter.
