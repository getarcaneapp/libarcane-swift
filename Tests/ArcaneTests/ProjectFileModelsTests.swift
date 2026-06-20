@testable import Arcane
import Foundation
import XCTest

final class ProjectFileModelsTests: XCTestCase {
    private let decoder = ArcaneJSON.makeDecoder()
    private let encoder = ArcaneJSON.makeEncoder()

    func testProjectDetailsDecodesManagedProjectFilesAndRevision() throws {
        let json = #"""
        {
            "id": "project-id",
            "name": "Project",
            "path": "/srv/projects/project",
            "status": "running",
            "serviceCount": 1,
            "runningCount": 1,
            "isArchived": false,
            "createdAt": "2026-06-20T00:00:00Z",
            "updatedAt": "2026-06-20T00:00:00Z",
            "fileTreeRevision": "revision-1",
            "projectFiles": [
                {
                    "path": "/srv/projects/project/config/app.yaml",
                    "relativePath": "config/app.yaml",
                    "name": "app.yaml",
                    "isDirectory": false,
                    "size": 24,
                    "modTime": "2026-06-20T00:01:00Z",
                    "protected": true,
                    "content": "enabled: true\n"
                },
                {
                    "path": "/srv/projects/project/config",
                    "relativePath": "config",
                    "name": "config",
                    "isDirectory": true,
                    "size": 0,
                    "modTime": "2026-06-20T00:00:30Z"
                }
            ]
        }
        """#

        let project = try decoder.decode(ProjectDetails.self, from: Data(json.utf8))

        XCTAssertEqual(project.fileTreeRevision, "revision-1")
        XCTAssertEqual(project.projectFiles?.count, 2)
        XCTAssertEqual(project.projectFiles?.first?.relativePath, "config/app.yaml")
        XCTAssertEqual(project.projectFiles?.first?.protected, true)
        XCTAssertEqual(project.projectFiles?.first?.content, "enabled: true\n")
        XCTAssertEqual(project.projectFiles?.last?.isDirectory, true)
    }

    func testCreateProjectEncodesManagedProjectFileDrafts() throws {
        let request = CreateProject(
            name: "with-files",
            composeContent: "services: {}\n",
            envContent: nil,
            projectFiles: [
                ProjectFileDraft(relativePath: "config", isDirectory: true),
                ProjectFileDraft(relativePath: "config/app.yaml", isDirectory: false, content: "enabled: true\n")
            ]
        )

        let json = try encodedJSONObject(request)

        XCTAssertEqual(json["name"] as? String, "with-files")
        let projectFiles = try XCTUnwrap(json["projectFiles"] as? [[String: Any]])
        XCTAssertEqual(projectFiles.count, 2)
        XCTAssertEqual(projectFiles[0]["relativePath"] as? String, "config")
        XCTAssertEqual(projectFiles[0]["isDirectory"] as? Bool, true)
        XCTAssertNil(projectFiles[0]["content"])
        XCTAssertEqual(projectFiles[1]["relativePath"] as? String, "config/app.yaml")
        XCTAssertEqual(projectFiles[1]["isDirectory"] as? Bool, false)
        XCTAssertEqual(projectFiles[1]["content"] as? String, "enabled: true\n")
    }

    func testUpdateProjectEncodesManagedProjectFileChangesAndRevision() throws {
        let updatedContent = "enabled: false\n"
        let request = UpdateProject(
            name: nil,
            composeContent: nil,
            envContent: "TOKEN=value\n",
            fileTreeRevision: "revision-1",
            fileChanges: [
                ProjectFileChange(
                    operation: .updateFile,
                    relativePath: "config/app.yaml",
                    content: updatedContent
                ),
                ProjectFileChange(
                    operation: .rename,
                    relativePath: "config/app.yaml",
                    newName: "app.prod.yaml"
                ),
                ProjectFileChange(
                    operation: .delete,
                    relativePath: "old",
                    recursive: true
                )
            ]
        )

        let json = try encodedJSONObject(request)

        XCTAssertEqual(json["envContent"] as? String, "TOKEN=value\n")
        XCTAssertEqual(json["fileTreeRevision"] as? String, "revision-1")
        let changes = try XCTUnwrap(json["fileChanges"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 3)
        XCTAssertEqual(changes[0]["operation"] as? String, "update_file")
        XCTAssertEqual(changes[0]["relativePath"] as? String, "config/app.yaml")
        XCTAssertEqual(changes[0]["content"] as? String, updatedContent)
        XCTAssertEqual(changes[1]["operation"] as? String, "rename")
        XCTAssertEqual(changes[1]["newName"] as? String, "app.prod.yaml")
        XCTAssertEqual(changes[2]["operation"] as? String, "delete")
        XCTAssertEqual(changes[2]["recursive"] as? Bool, true)
    }

    private func encodedJSONObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try encoder.encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }
}
