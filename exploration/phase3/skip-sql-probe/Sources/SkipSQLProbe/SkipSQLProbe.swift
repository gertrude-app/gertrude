import SkipSQLPlus
import Foundation

func runSQLProbe() throws -> String {
    let db = try SQLContext(path: ":memory:", configuration: .plus)

    try db.exec(sql: """
        CREATE TABLE episode (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL
        )
    """)

    let insertSQL = "INSERT INTO episode (title, duration_seconds) VALUES (?, ?)"
    try db.exec(sql: insertSQL, parameters: [.text("Episode 1: Intro"), .long(1800)])
    try db.exec(sql: insertSQL, parameters: [.text("Episode 2: Deep Dive"), .long(3600)])
    try db.exec(sql: insertSQL, parameters: [.text("Episode 3: Q&A"), .long(2400)])

    let rows = try db.selectAll(sql: "SELECT id, title, duration_seconds FROM episode ORDER BY id")
    var results: [String] = []
    for row in rows {
        if case .text(let title) = row[1], case .long(let duration) = row[2] {
            results.append("\(title) (\(duration)s)")
        }
    }

    return "Fetched \(results.count) episodes: \(results.joined(separator: ", "))"
}
