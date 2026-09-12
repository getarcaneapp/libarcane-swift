import Foundation
import Testing

@testable import Arcane

@Suite struct ProjectTagTests {
  @Test func decodesComposeAndUITags() throws {
    let project = try decodeProject(tags: """
      ,"tags":[{"name":"Media","color":"purple","sources":["compose","ui"]}]
      """)
    #expect(project.tags == [ProjectTag(name: "Media", color: "purple", sources: ["compose", "ui"])])
    let roundTrip = try ArcaneJSON.makeDecoder().decode(
      ProjectDetails.self, from: JSONEncoder().encode(project))
    #expect(roundTrip.tags == project.tags)
  }

  @Test func acceptsLegacyAndEmptyTags() throws {
    #expect(try decodeProject(tags: "").tags == nil)
    #expect(try decodeProject(tags: #", "tags":null"#).tags == nil)
    #expect(try decodeProject(tags: #", "tags":[]"#).tags == [])
  }

  private func decodeProject(tags: String) throws -> ProjectDetails {
    try ArcaneJSON.makeDecoder().decode(ProjectDetails.self, from: Data("""
      {"id":"project-1","name":"media","path":"/projects/media","status":"running",
       "serviceCount":1,"runningCount":1,"isArchived":false,"createdAt":"","updatedAt":""\(tags)}
      """.utf8))
  }
}
