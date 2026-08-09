import Api
import Dependencies
import DuetSQL
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

if CommandLine.arguments.contains("ts-codegen") {
  app.asyncCommands.use(TsCodegenCommand(), as: "ts-codegen")
  try app.run()
} else if CommandLine.arguments.contains("scrub-db") {
  try withDependencies { deps in
    deps.logger = app.logger
    deps.uuid = UUIDGenerator { UUID() }
    deps.env = .fromProcess(mode: app.environment)
    deps.db = PgClient(threadCount: System.coreCount, env: deps.env)
  } operation: {
    app.asyncCommands.use(ScrubDbCommand(), as: "scrub-db")
    try app.run()
  }
} else if CommandLine.arguments.contains("scheduled-marketing-email-dry-run") {
  try withDependencies { deps in
    deps.logger = app.logger
    deps.uuid = UUIDGenerator { UUID() }
    deps.env = .fromProcess(mode: app.environment)
    deps.db = PgClient(threadCount: System.coreCount, env: deps.env)
  } operation: {
    app.asyncCommands.use(
      ScheduledMarketingEmailCampaignDryRunCommand(),
      as: "scheduled-marketing-email-dry-run",
    )
    try app.run()
  }
} else {
  try withDependencies { deps in
    deps.logger = app.logger
    deps.uuid = UUIDGenerator { UUID() }
    deps.env = .fromProcess(mode: app.environment)
    deps.stripe = .liveValue
    deps.db = PgClient(threadCount: System.coreCount, env: deps.env)
    deps.aws = .liveValue
  } operation: {
    try Configure.app(app)
    try app.run()
  }
}
