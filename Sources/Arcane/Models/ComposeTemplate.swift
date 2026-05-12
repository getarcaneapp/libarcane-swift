import Foundation

nonisolated public struct ComposeTemplate: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let content: String
    public let envContent: String?
    public let isCustom: Bool
    public let isRemote: Bool
    public let registryId: String?
    public let registry: TemplateRegistry?
    public let metadata: ComposeTemplateMetadata?

    public var iconUrl: String? { metadata?.iconUrl }

    public enum CodingKeys: String, CodingKey {
        case id, name, description, content, envContent
        case isCustom, isRemote, registryId, registry, metadata
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        self.description = (try? container.decodeIfPresent(String.self, forKey: .description)) ?? ""
        self.content = (try? container.decodeIfPresent(String.self, forKey: .content)) ?? ""
        self.envContent = try? container.decodeIfPresent(String.self, forKey: .envContent)
        self.isCustom = (try? container.decodeIfPresent(Bool.self, forKey: .isCustom)) ?? false
        self.isRemote = (try? container.decodeIfPresent(Bool.self, forKey: .isRemote)) ?? false
        self.registryId = try? container.decodeIfPresent(String.self, forKey: .registryId)
        self.registry = try? container.decodeIfPresent(TemplateRegistry.self, forKey: .registry)
        self.metadata = try? container.decodeIfPresent(ComposeTemplateMetadata.self, forKey: .metadata)
    }
}

nonisolated public struct ComposeTemplateMetadata: Codable, Hashable, Sendable {
    public let iconUrl: String?
    public let categories: [String]?
    public let documentationUrl: String?

    public enum CodingKeys: String, CodingKey {
        case iconUrl, categories, documentationUrl
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.iconUrl = try? container.decodeIfPresent(String.self, forKey: .iconUrl)
        self.categories = try? container.decodeIfPresent([String].self, forKey: .categories)
        self.documentationUrl = try? container.decodeIfPresent(String.self, forKey: .documentationUrl)
    }
}

nonisolated public struct ComposeTemplateContent: Codable, Hashable, Sendable {
    public let content: String
    public let envContent: String
    public let template: ComposeTemplate

    public enum CodingKeys: String, CodingKey {
        case content, envContent, template
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = (try? container.decodeIfPresent(String.self, forKey: .content)) ?? ""
        self.envContent = (try? container.decodeIfPresent(String.self, forKey: .envContent)) ?? ""
        self.template = try container.decode(ComposeTemplate.self, forKey: .template)
    }
}
