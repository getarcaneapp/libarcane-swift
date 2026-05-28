import Foundation

/// Well-known permission strings recognized by the Arcane v2 RBAC system.
///
/// Use these constants when calling `User.hasPermission(_:environmentID:)`
/// or when building role definitions via `CreateRole` / `UpdateRole`. Custom
/// permission strings are also accepted — the SDK treats permissions as
/// free-form strings and does no client-side validation.
public enum Permission {
    /// Sudo wildcard. A user holding `"*"` in any in-scope permission bucket
    /// (global or the queried environment) passes every permission check.
    public static let sudo = "*"

    public enum Containers {
        public static let list = "containers:list"
        public static let read = "containers:read"
        public static let logs = "containers:logs"
        public static let create = "containers:create"
        public static let start = "containers:start"
        public static let stop = "containers:stop"
        public static let restart = "containers:restart"
        public static let redeploy = "containers:redeploy"
        public static let delete = "containers:delete"
        public static let exec = "containers:exec"
        public static let autoUpdate = "containers:autoupdate"
    }

    public enum Projects {
        public static let list = "projects:list"
        public static let read = "projects:read"
        public static let logs = "projects:logs"
        public static let create = "projects:create"
        public static let update = "projects:update"
        public static let deploy = "projects:deploy"
        public static let down = "projects:down"
        public static let restart = "projects:restart"
        public static let delete = "projects:delete"
        public static let archive = "projects:archive"
    }

    public enum Images {
        public static let list = "images:list"
        public static let read = "images:read"
        public static let pull = "images:pull"
        public static let push = "images:push"
        public static let build = "images:build"
        public static let prune = "images:prune"
        public static let delete = "images:delete"
        public static let upload = "images:upload"
    }

    public enum Volumes {
        public static let list = "volumes:list"
        public static let read = "volumes:read"
        public static let create = "volumes:create"
        public static let delete = "volumes:delete"
        public static let prune = "volumes:prune"
        public static let browse = "volumes:browse"
        public static let upload = "volumes:upload"
        public static let backup = "volumes:backup"
    }

    public enum Networks {
        public static let list = "networks:list"
        public static let read = "networks:read"
        public static let create = "networks:create"
        public static let delete = "networks:delete"
        public static let prune = "networks:prune"
    }

    public enum Swarm {
        public static let read = "swarm:read"
        public static let initialize = "swarm:init"
        public static let join = "swarm:join"
        public static let leave = "swarm:leave"
        public static let spec = "swarm:spec"
        public static let nodes = "swarm:nodes"
        public static let services = "swarm:services"
        public static let servicesLogs = "swarm:services:logs"
        public static let stacks = "swarm:stacks"
        public static let configs = "swarm:configs"
        public static let secrets = "swarm:secrets"
        public static let unlock = "swarm:unlock"
    }

    public enum Users {
        public static let list = "users:list"
        public static let read = "users:read"
        public static let create = "users:create"
        public static let update = "users:update"
        public static let delete = "users:delete"
    }

    public enum Roles {
        public static let list = "roles:list"
        public static let read = "roles:read"
    }

    public enum ApiKeys {
        public static let list = "apikeys:list"
        public static let read = "apikeys:read"
        public static let create = "apikeys:create"
        public static let update = "apikeys:update"
        public static let delete = "apikeys:delete"
    }

    public enum Settings {
        public static let read = "settings:read"
        public static let write = "settings:write"
    }

    public enum Environments {
        public static let list = "environments:list"
        public static let read = "environments:read"
        public static let create = "environments:create"
        public static let update = "environments:update"
        public static let delete = "environments:delete"
        public static let pair = "environments:pair"
        public static let sync = "environments:sync"
    }

    public enum Registries {
        public static let list = "registries:list"
        public static let read = "registries:read"
        public static let create = "registries:create"
        public static let update = "registries:update"
        public static let delete = "registries:delete"
        public static let test = "registries:test"
    }

    public enum Templates {
        public static let list = "templates:list"
        public static let read = "templates:read"
        public static let create = "templates:create"
        public static let update = "templates:update"
        public static let delete = "templates:delete"
    }

    public enum GitRepositories {
        public static let list = "git-repositories:list"
        public static let read = "git-repositories:read"
        public static let create = "git-repositories:create"
        public static let update = "git-repositories:update"
        public static let delete = "git-repositories:delete"
        public static let test = "git-repositories:test"
        public static let sync = "git-repositories:sync"
    }

    public enum GitOps {
        public static let list = "gitops:list"
        public static let read = "gitops:read"
        public static let create = "gitops:create"
        public static let update = "gitops:update"
        public static let delete = "gitops:delete"
        public static let sync = "gitops:sync"
    }

    public enum Webhooks {
        public static let list = "webhooks:list"
        public static let create = "webhooks:create"
        public static let update = "webhooks:update"
        public static let delete = "webhooks:delete"
    }

    public enum System {
        public static let read = "system:read"
        public static let prune = "system:prune"
        public static let upgrade = "system:upgrade"
    }

    public enum Vulnerabilities {
        public static let read = "vulnerabilities:read"
        public static let scan = "vulnerabilities:scan"
        public static let manage = "vulnerabilities:manage"
    }

    public enum ImageUpdates {
        public static let read = "image-updates:read"
        public static let check = "image-updates:check"
    }

    public enum Events {
        public static let read = "events:read"
    }

    public enum Dashboard {
        public static let read = "dashboard:read"
    }

    public enum Jobs {
        public static let manage = "jobs:manage"
    }

    public enum Notifications {
        public static let manage = "notifications:manage"
    }

    public enum Customize {
        public static let manage = "customize:manage"
    }

    public enum BuildWorkspaces {
        public static let manage = "build-workspaces:manage"
    }
}
