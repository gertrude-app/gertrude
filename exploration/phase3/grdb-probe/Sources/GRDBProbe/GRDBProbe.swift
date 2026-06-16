import Foundation
import GRDB

struct Episode: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var title: String
    var durationSeconds: Int
}

func runGRDBTest() throws -> String {
    let dbQueue = try DatabaseQueue()

    try dbQueue.write { db in
        try db.create(table: "episode") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("title", .text).notNull()
            t.column("durationSeconds", .integer).notNull()
        }

        try Episode(id: nil, title: "Episode 1: Intro", durationSeconds: 1800).insert(db)
        try Episode(id: nil, title: "Episode 2: Deep Dive", durationSeconds: 3600).insert(db)
    }

    let episodes = try dbQueue.read { db in
        try Episode.fetchAll(db)
    }

    return "Fetched \(episodes.count) episodes: \(episodes.map(\.title).joined(separator: ", "))"
}
