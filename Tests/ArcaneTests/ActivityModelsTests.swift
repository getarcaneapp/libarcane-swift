@testable import Arcane
import Foundation
import XCTest

final class ActivityModelsTests: XCTestCase {
    private let decoder = ArcaneJSON.makeDecoder()

    func testServerCapabilitiesExposeActivitiesOnlyForV2() {
        XCTAssertFalse(ServerCapabilities(mode: .legacyRoles).supportsActivities)
        XCTAssertTrue(ServerCapabilities(mode: .rbac).supportsActivities)
    }

    func testDecodeActivityDetailAndStreamEvent() throws {
        let detailJSON = #"""
        {
            "activity": {
                "id": "act_1",
                "environmentId": "env_1",
                "sourceEnvironmentId": "edge_1",
                "sourceEnvironmentName": "Edge Node",
                "type": "project_deploy",
                "status": "running",
                "resourceType": "project",
                "resourceId": "proj_1",
                "resourceName": "homepage",
                "progress": 65,
                "step": "Pulling images",
                "latestMessage": "Pulling nginx:latest",
                "startedBy": {
                    "userId": "u_1",
                    "username": "admin",
                    "displayName": "Admin"
                },
                "startedAt": "2026-06-01T15:00:00Z",
                "metadata": { "project": "homepage" },
                "createdAt": "2026-06-01T15:00:00Z",
                "updatedAt": "2026-06-01T15:00:10Z"
            },
            "messages": [
                {
                    "id": "msg_1",
                    "activityId": "act_1",
                    "level": "info",
                    "message": "Pulling nginx:latest",
                    "payload": { "image": "nginx:latest" },
                    "createdAt": "2026-06-01T15:00:05Z"
                }
            ]
        }
        """#

        let detail = try decoder.decode(ActivityDetail.self, from: Data(detailJSON.utf8))
        XCTAssertEqual(detail.activity.id, "act_1")
        XCTAssertEqual(detail.activity.status, .running)
        XCTAssertEqual(detail.activity.type, .projectDeploy)
        XCTAssertEqual(detail.activity.sourceEnvironmentName, "Edge Node")
        XCTAssertEqual(detail.activity.startedBy?.displayName, "Admin")
        XCTAssertEqual(detail.messages.first?.level, .info)
        XCTAssertEqual(detail.messages.first?.payload?["image"]?.stringValue, "nginx:latest")

        let streamJSON = #"""
        {
            "type": "message",
            "activityId": "act_1",
            "message": {
                "id": "msg_2",
                "activityId": "act_1",
                "level": "success",
                "message": "Done",
                "createdAt": "2026-06-01T15:01:00Z"
            },
            "timestamp": "2026-06-01T15:01:00Z"
        }
        """#
        let event = try decoder.decode(ActivityStreamEvent.self, from: Data(streamJSON.utf8))
        XCTAssertEqual(event.type, .message)
        XCTAssertEqual(event.activityID, "act_1")
        XCTAssertEqual(event.message?.level, .success)
    }
}
