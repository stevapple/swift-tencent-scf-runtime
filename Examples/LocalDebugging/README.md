# Local Debugging Example

This sample project demonstrates how to write a simple SCF function in Swift, and how to use local debugging techniques that simulate how the SCF function would be invoked by the Tencent SCF Runtime engine.

The example includes an Xcode workspace with three modules:

1. [MyApp](MyApp) is a SwiftUI iOS application that calls the SCF function.
2. [MyCloudFunction](MyCloudFunction) is a SwiftPM executable package for the SCF function.
3. [Shared](Shared) is a SwiftPM library package used for shared code between the iOS application and the Lambda function, such as the Request and Response model objects.

The local debugging experience is achieved by running the SCF function in the context of the debug-only local lambda engine simulator which starts a local HTTP server enabling the communication between the iOS application and the SCF function over HTTP.

To try out this example, open the workspace in Xcode and "run" the two targets, using the relevant `MyCloudFunction` and `MyApp` Xcode schemes.

Start with running the `MyCloudFunction` target.
* Switch to the `MyCloudFunction` scheme and select the "My Mac" destination
* Set the `LOCAL_SCF_SERVER_ENABLED` environment variable to `true` by editing the `MyCloudFunction` scheme Run/Arguments options.
* Hit `Run`
* Once it is up you should see a log message in the Xcode console saying `LocalSCFServer started and listening on 127.0.0.1:9001, receiving events on /invoke` which means the local emulator is up and receiving traffic on port `9001` and expecting events on the `/invoke` endpoint.

Continue to run the `MyApp` target
* Switch to the `MyApp` scheme and select a simulator destination.
* Hit `Run`
* Once up, the application's UI should appear in the simulator allowing you to interact with it.

Once both targets are running, set up breakpoints in the iOS application or cloud function to observe the system behavior.
