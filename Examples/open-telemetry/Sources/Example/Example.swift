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

        router.get("/compute/:x") { _, context in
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

        router.get("/multi") { _, _ in
            _ = await valkeyClient.execute(
                EVAL(script: "return '1'"),
                EVAL(script: "return '2'"),
                EVAL(script: "return '3'")
            )
            return HTTPResponse.Status.ok
        }

        router.get("/error") { _, _ in
            _ = try? await valkeyClient.eval(script: "not a script")
            return HTTPResponse.Status.ok
        }

        var app = Application(router: router)
        app.addServices(observability, valkeyClient)

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
