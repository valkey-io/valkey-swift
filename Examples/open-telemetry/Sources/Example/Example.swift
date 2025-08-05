import Hummingbird
import Logging
import OTel
import ServiceLifecycle
import Tracing
import Valkey

@main
struct Example {
    static func main() async throws {
        let observability = try bootstrapObservability()
        let logger = Logger(label: "example")

        let valkeyClient = ValkeyClient(
            .hostname("localhost"),
            logger: logger
        )

        let router = Router()
        router.add(middleware: TracingMiddleware())
        router.add(middleware: LogRequestsMiddleware(.info))

        router.get("/:x") { _, context in
            /*
             This demonstrates the span created for pipelined commands where all commands are of the same type.
             The `db.operation.name` indicates that it's multiple `EVAL` commands,
             and `db.operation.batch.size` indicates the number of commands.
             */
            _ = await valkeyClient.execute(
                EVAL(script: "return '1'"),
                EVAL(script: "return '2'"),
                EVAL(script: "return '3'")
            )

            /*
             This demonstrates the span created for pipelined commands where the commands are of different types.
             The `db.operation.name` resorts to `MULTI`, and `db.operation.batch.size` indicates the number of commands.
             */
            _ = await valkeyClient.execute(
                EVAL(script: "return '1'"),
                ACL.WHOAMI()
            )

            // This demonstrates the span created for a failed command.
            _ = try? await valkeyClient.execute(EVAL(script: "💩"))

            // This demonstrates the span created for a failed pipelined command.
            _ = await valkeyClient.execute(
                EVAL(script: "return 'ok'"),
                EVAL(script: "💩")
            )

            let x = try context.parameters.require("x", as: Int.self)

            func expensiveAlgorithm(_ x: Int) async throws -> Int {
                try await withSpan("compute") { span in
                    span.attributes["input"] = x
                    try await Task.sleep(for: .seconds(3))
                    return x * 2
                }
            }

            if let cachedResult = try await valkeyClient.hget("values", field: "\(x)") {
                return cachedResult
            }

            let result = try await expensiveAlgorithm(x)

            try await valkeyClient.hset("values", data: [.init(field: "\(x)", value: "\(result)")])

            return ByteBuffer(string: "\(result)")
        }

        var app = Application(router: router)
        app.addServices(observability)
        app.addServices(valkeyClient)

        try await app.runService()
    }

    private static func bootstrapObservability() throws -> some Service {
        LoggingSystem.bootstrap(
            StreamLogHandler.standardOutput(label:metadataProvider:),
            metadataProvider: OTel.makeLoggingMetadataProvider()
        )

        var configuration = OTel.Configuration.default
        configuration.serviceName = "example"

        // For now, valkey-swift only supports Distributed Tracing so we disable the other signals.
        configuration.logs.enabled = false
        configuration.metrics.enabled = false

        return try OTel.bootstrap(configuration: configuration)
    }
}
