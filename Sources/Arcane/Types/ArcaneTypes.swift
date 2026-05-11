import ArcaneAPI

// MARK: - Base

public typealias MessageResponse = Components.Schemas.BaseMessageResponse
public typealias PaginationResponse = Components.Schemas.BasePaginationResponse
public typealias ErrorModel = Components.Schemas.ErrorModel
public typealias ErrorDetail = Components.Schemas.ErrorDetail

// MARK: - Auth

public typealias LoginRequest = Components.Schemas.AuthLogin
public typealias LoginResponse = Components.Schemas.AuthLoginResponse
public typealias RefreshRequest = Components.Schemas.AuthRefresh
public typealias TokenRefreshResponse = Components.Schemas.AuthTokenRefreshResponse
public typealias PasswordChange = Components.Schemas.AuthPasswordChange
public typealias OidcAuthUrlRequest = Components.Schemas.AuthOidcAuthUrlRequest
public typealias OidcAuthUrlResponse = Components.Schemas.AuthOidcAuthUrlResponse
public typealias OidcCallbackRequest = Components.Schemas.AuthOidcCallbackRequest
public typealias OidcCallbackResponse = Components.Schemas.AuthOidcCallbackResponse
public typealias OidcConfigResponse = Components.Schemas.AuthOidcConfigResponse
public typealias OidcDeviceAuthResponse = Components.Schemas.AuthOidcDeviceAuthResponse
public typealias OidcDeviceTokenRequest = Components.Schemas.AuthOidcDeviceTokenRequest
public typealias OidcDeviceTokenResponse = Components.Schemas.AuthOidcDeviceTokenResponse
public typealias OidcStatusInfo = Components.Schemas.AuthOidcStatusInfo

// MARK: - API Keys

public typealias ApiKey = Components.Schemas.ApikeyApiKey
public typealias ApiKeyCreatedDto = Components.Schemas.ApikeyApiKeyCreatedDto
public typealias CreateApiKey = Components.Schemas.ApikeyCreateApiKey
public typealias UpdateApiKey = Components.Schemas.ApikeyUpdateApiKey
public typealias ApiKeyPaginatedResponse = Components.Schemas.ApiKeyPaginatedResponse

// MARK: - Users

public typealias CreateUser = Components.Schemas.UserCreateUser
public typealias UpdateUser = Components.Schemas.UserUpdateUser
public typealias User = Components.Schemas.UserUser
public typealias UserPaginatedResponse = Components.Schemas.UserPaginatedResponse

// MARK: - Environments

public typealias Environment = Components.Schemas.EnvironmentEnvironment
public typealias EnvironmentCreate = Components.Schemas.EnvironmentCreate
public typealias EnvironmentUpdate = Components.Schemas.EnvironmentUpdate
public typealias EnvironmentTest = Components.Schemas.EnvironmentTest
public typealias EnvironmentTestConnectionRequest = Components.Schemas.EnvironmentTestConnectionRequest
public typealias EnvironmentEdgeMTLSCertificate = Components.Schemas.EnvironmentEdgeMTLSCertificate
public typealias EnvironmentAgentPairRequest = Components.Schemas.EnvironmentAgentPairRequest
public typealias EnvironmentAgentPairResponse = Components.Schemas.EnvironmentAgentPairResponse
public typealias EnvironmentWithApiKey = Components.Schemas.EnvironmentWithApiKey
public typealias EnvironmentPaginatedResponse = Components.Schemas.EnvironmentPaginatedResponse

// MARK: - Containers

public typealias ContainerCreate = Components.Schemas.ContainerCreate
public typealias ContainerCreated = Components.Schemas.ContainerCreated
public typealias ContainerCreatedResponse = Components.Schemas.ContainerCreatedResponse
public typealias ContainerSummary = Components.Schemas.ContainerSummary
public typealias ContainerSummaryGroup = Components.Schemas.ContainerSummaryGroup
public typealias ContainerDetails = Components.Schemas.ContainerDetails
public typealias ContainerDetailsResponse = Components.Schemas.ContainerDetailsResponse
public typealias ContainerStatusCounts = Components.Schemas.ContainerStatusCounts
public typealias ContainerStatusCountsResponse = Components.Schemas.ContainerStatusCountsResponse
public typealias ContainerActionResult = Components.Schemas.ContainerActionResult
public typealias ContainerActionResponse = Components.Schemas.ContainerActionResponse
public typealias ContainerPort = Components.Schemas.ContainerPort
public typealias ContainerMount = Components.Schemas.ContainerMount
public typealias ContainerNetworkEndpoint = Components.Schemas.ContainerNetworkEndpoint
public typealias ContainerNetworkSettings = Components.Schemas.ContainerNetworkSettings
public typealias ContainerState = Components.Schemas.ContainerState
public typealias ContainerHealth = Components.Schemas.ContainerHealth
public typealias ContainerHealthLogEntry = Components.Schemas.ContainerHealthLogEntry
public typealias ContainerHealthcheck = Components.Schemas.ContainerHealthcheck
public typealias ContainerConfig = Components.Schemas.ContainerConfig
public typealias ContainerHostConfig = Components.Schemas.ContainerHostConfig
public typealias ContainerComposeInfo = Components.Schemas.ContainerComposeInfo
public typealias ContainerPaginatedResponse = Components.Schemas.ContainerPaginatedResponse
public typealias ContainerRestartPolicyCreate = Components.Schemas.ContainerRestartPolicyCreate
public typealias ContainerPortBindingCreate = Components.Schemas.ContainerPortBindingCreate
public typealias ContainerHostConfigCreate = Components.Schemas.ContainerHostConfigCreate
public typealias ContainerEndpointSettingsCreate = Components.Schemas.ContainerEndpointSettingsCreate
public typealias ContainerNetworkingConfigCreate = Components.Schemas.ContainerNetworkingConfigCreate

// MARK: - Images

public typealias ImageSummary = Components.Schemas.ImageSummary
public typealias ImageDetailSummary = Components.Schemas.ImageDetailSummary
public typealias ImagePullOptions = Components.Schemas.ImagePullOptions
public typealias ImageLoadResult = Components.Schemas.ImageLoadResult
public typealias ImagePruneReport = Components.Schemas.ImagePruneReport
public typealias ImageUsageCounts = Components.Schemas.ImageUsageCounts
public typealias ImageUsageCountsResponse = Components.Schemas.ImageUsageCountsResponse
public typealias ImageUsedBy = Components.Schemas.ImageUsedBy
public typealias ImagePaginatedResponse = Components.Schemas.ImagePaginatedResponse
public typealias ImageBuildRecord = Components.Schemas.ImageBuildRecord
public typealias ImageBuildRequest = Components.Schemas.ImageBuildRequest
public typealias ImageBuildPaginatedResponse = Components.Schemas.ImageBuildPaginatedResponse
public typealias ImageUpdateInfo = Components.Schemas.ImageUpdateInfo
public typealias ImageUpdateResponse = Components.Schemas.ImageupdateResponse
public typealias ImageUpdateSummary = Components.Schemas.ImageupdateSummary
public typealias BatchImageUpdateRequest = Components.Schemas.ImageupdateBatchImageUpdateRequest
public typealias CheckAllImagesRequest = Components.Schemas.ImageupdateCheckAllImagesRequest

// MARK: - Volumes

public typealias Volume = Components.Schemas.VolumeVolume
public typealias VolumeCreate = Components.Schemas.VolumeCreate
public typealias VolumeBackup = Components.Schemas.VolumeBackup
public typealias VolumeBackupPaginatedResponse = Components.Schemas.VolumeBackupPaginatedResponse
public typealias VolumeFileEntry = Components.Schemas.VolumeFileEntry
public typealias VolumePaginatedResponse = Components.Schemas.VolumePaginatedResponse
public typealias VolumePruneReportData = Components.Schemas.VolumePruneReportData
public typealias VolumeSizeInfo = Components.Schemas.VolumeSizeInfo
public typealias VolumeUsageCountsData = Components.Schemas.VolumeUsageCountsData
public typealias VolumeUsageResponse = Components.Schemas.VolumeUsageResponse

// MARK: - Networks

public typealias NetworkSummary = Components.Schemas.NetworkSummary
public typealias NetworkInspect = Components.Schemas.NetworkInspect
public typealias NetworkContainerEndpoint = Components.Schemas.NetworkContainerEndpoint
public typealias NetworkUsageCounts = Components.Schemas.NetworkUsageCounts
public typealias NetworkCreateRequest = Components.Schemas.NetworkCreateRequest
public typealias NetworkCreateResponse = Components.Schemas.NetworkCreateResponse
public typealias NetworkIPAM = Components.Schemas.NetworkIPAM
public typealias NetworkIPAMConfig = Components.Schemas.NetworkIPAMConfig
public typealias NetworkCreateOptions = Components.Schemas.NetworkCreateOptions
public typealias NetworkPruneReport = Components.Schemas.NetworkPruneReport
public typealias NetworkTopology = Components.Schemas.NetworkTopology
public typealias NetworkTopologyNode = Components.Schemas.NetworkTopologyNode
public typealias NetworkTopologyNodeMetadata = Components.Schemas.NetworkTopologyNodeMetadata
public typealias NetworkTopologyEdge = Components.Schemas.NetworkTopologyEdge
public typealias NetworkPaginatedResponse = Components.Schemas.NetworkPaginatedResponse

// MARK: - Projects

public typealias ProjectCreateProject = Components.Schemas.ProjectCreateProject
public typealias ProjectUpdateProject = Components.Schemas.ProjectUpdateProject
public typealias ProjectCreateReponse = Components.Schemas.ProjectCreateReponse
public typealias ProjectDetails = Components.Schemas.ProjectDetails
public typealias ProjectRuntimeService = Components.Schemas.ProjectRuntimeService
public typealias ProjectDeployOptions = Components.Schemas.ProjectDeployOptions
public typealias ProjectDestroy = Components.Schemas.ProjectDestroy
public typealias ProjectIncludeFile = Components.Schemas.ProjectIncludeFile
public typealias ProjectUpdateIncludeFile = Components.Schemas.ProjectUpdateIncludeFile
public typealias ProjectStatusCounts = Components.Schemas.ProjectStatusCounts
public typealias ProjectUpdateInfo = Components.Schemas.ProjectUpdateInfo
public typealias ProjectPaginatedResponse = Components.Schemas.ProjectPaginatedResponse

// MARK: - Swarm

public typealias SwarmRuntimeStatus = Components.Schemas.SwarmRuntimeStatus
public typealias SwarmInfo = Components.Schemas.SwarmSwarmInfo
public typealias SwarmInitRequest = Components.Schemas.SwarmSwarmInitRequest
public typealias SwarmInitResponse = Components.Schemas.SwarmSwarmInitResponse
public typealias SwarmJoinRequest = Components.Schemas.SwarmSwarmJoinRequest
public typealias SwarmLeaveRequest = Components.Schemas.SwarmSwarmLeaveRequest
public typealias SwarmUnlockRequest = Components.Schemas.SwarmSwarmUnlockRequest
public typealias SwarmUnlockKeyResponse = Components.Schemas.SwarmSwarmUnlockKeyResponse
public typealias SwarmJoinTokensResponse = Components.Schemas.SwarmSwarmJoinTokensResponse
public typealias SwarmRotateJoinTokensRequest = Components.Schemas.SwarmSwarmRotateJoinTokensRequest
public typealias SwarmUpdateRequest = Components.Schemas.SwarmSwarmUpdateRequest
public typealias SwarmNodeSummary = Components.Schemas.SwarmNodeSummary
public typealias SwarmNodeAgentStatus = Components.Schemas.SwarmNodeAgentStatus
public typealias SwarmNodeUpdateRequest = Components.Schemas.SwarmNodeUpdateRequest
public typealias SwarmServiceSummary = Components.Schemas.SwarmServiceSummary
public typealias SwarmServiceInspect = Components.Schemas.SwarmServiceInspect
public typealias SwarmServiceCreateRequest = Components.Schemas.SwarmServiceCreateRequest
public typealias SwarmServiceUpdateRequest = Components.Schemas.SwarmServiceUpdateRequest
public typealias SwarmServiceCreateResponse = Components.Schemas.SwarmServiceCreateResponse
public typealias SwarmServiceUpdateResponse = Components.Schemas.SwarmServiceUpdateResponse
public typealias SwarmServiceCreateOptions = Components.Schemas.SwarmServiceCreateOptions
public typealias SwarmServiceUpdateOptions = Components.Schemas.SwarmServiceUpdateOptions
public typealias SwarmServiceScaleRequest = Components.Schemas.SwarmServiceScaleRequest
public typealias SwarmServicePort = Components.Schemas.SwarmServicePort
public typealias SwarmServiceMount = Components.Schemas.SwarmServiceMount
public typealias SwarmStackSummary = Components.Schemas.SwarmStackSummary
public typealias SwarmStackInspect = Components.Schemas.SwarmStackInspect
public typealias SwarmStackDeployRequest = Components.Schemas.SwarmStackDeployRequest
public typealias SwarmStackDeployResponse = Components.Schemas.SwarmStackDeployResponse
public typealias SwarmStackRenderConfigRequest = Components.Schemas.SwarmStackRenderConfigRequest
public typealias SwarmStackRenderConfigResponse = Components.Schemas.SwarmStackRenderConfigResponse
public typealias SwarmStackSource = Components.Schemas.SwarmStackSource
public typealias SwarmStackSourceUpdateRequest = Components.Schemas.SwarmStackSourceUpdateRequest
public typealias SwarmSyncFile = Components.Schemas.SwarmSyncFile
public typealias SwarmTaskSummary = Components.Schemas.SwarmTaskSummary
public typealias SwarmConfigSummary = Components.Schemas.SwarmConfigSummary
public typealias SwarmSecretSummary = Components.Schemas.SwarmSecretSummary
public typealias SwarmConfigCreateRequest = Components.Schemas.SwarmConfigCreateRequest
public typealias SwarmConfigUpdateRequest = Components.Schemas.SwarmConfigUpdateRequest
public typealias SwarmSecretCreateRequest = Components.Schemas.SwarmSecretCreateRequest
public typealias SwarmSecretUpdateRequest = Components.Schemas.SwarmSecretUpdateRequest

// MARK: - GitOps

public typealias GitRepository = Components.Schemas.GitopsGitRepository
public typealias GitOpsSync = Components.Schemas.GitopsGitOpsSync
public typealias GitOpsSyncCounts = Components.Schemas.GitopsSyncCounts
public typealias CreateGitRepositoryRequest = Components.Schemas.CreateGitRepositoryRequest
public typealias UpdateGitRepositoryRequest = Components.Schemas.UpdateGitRepositoryRequest
public typealias CreateGitOpsSyncRequest = Components.Schemas.GitopsCreateSyncRequest
public typealias UpdateGitOpsSyncRequest = Components.Schemas.GitopsUpdateSyncRequest
public typealias GitOpsSyncResult = Components.Schemas.GitopsSyncResult
public typealias GitOpsFileTreeNode = Components.Schemas.GitopsFileTreeNode
public typealias GitOpsBrowseResponse = Components.Schemas.GitopsBrowseResponse
public typealias GitOpsBranchInfo = Components.Schemas.GitopsBranchInfo
public typealias GitOpsBranchesResponse = Components.Schemas.GitopsBranchesResponse
public typealias GitOpsRepositorySync = Components.Schemas.GitopsRepositorySync
public typealias GitOpsRepositorySyncRequest = Components.Schemas.GitopsRepositorySyncRequest
public typealias GitOpsSyncStatus = Components.Schemas.GitopsSyncStatus
public typealias ImportGitOpsSyncRequest = Components.Schemas.GitopsImportGitOpsSyncRequest
public typealias ImportGitOpsSyncResponse = Components.Schemas.GitopsImportGitOpsSyncResponse
public typealias GitRepositoryPaginatedResponse = Components.Schemas.GitRepositoryPaginatedResponse
public typealias GitOpsSyncPaginatedResponse = Components.Schemas.GitOpsSyncPaginatedResponse

// MARK: - System

public typealias SystemHealthResponse = Components.Schemas.SystemHealthResponse
public typealias ConvertDockerRunRequest = Components.Schemas.SystemConvertDockerRunRequest
public typealias ConvertDockerRunResponse = Components.Schemas.SystemConvertDockerRunResponse
public typealias SystemPruneAllRequest = Components.Schemas.SystemPruneAllRequest
public typealias SystemPruneAllResult = Components.Schemas.SystemPruneAllResult
public typealias SystemPruneBuildCacheOptions = Components.Schemas.SystemPruneBuildCacheOptions
public typealias SystemPruneContainersOptions = Components.Schemas.SystemPruneContainersOptions
public typealias SystemPruneImagesOptions = Components.Schemas.SystemPruneImagesOptions
public typealias SystemPruneNetworksOptions = Components.Schemas.SystemPruneNetworksOptions
public typealias SystemPruneVolumesOptions = Components.Schemas.SystemPruneVolumesOptions

// MARK: - Settings, Dashboard, Events, Notifications

public typealias SettingDto = Components.Schemas.SettingsSettingDto
public typealias PublicSetting = Components.Schemas.SettingsPublicSetting
public typealias SettingsUpdate = Components.Schemas.SettingsUpdate
public typealias DashboardSnapshot = Components.Schemas.DashboardSnapshot
public typealias DashboardActionItem = Components.Schemas.DashboardActionItem
public typealias DashboardActionItems = Components.Schemas.DashboardActionItems
public typealias DashboardEnvironmentOverview = Components.Schemas.DashboardEnvironmentOverview
public typealias DashboardEnvironmentsOverview = Components.Schemas.DashboardEnvironmentsOverview
public typealias DashboardEnvironmentsSummary = Components.Schemas.DashboardEnvironmentsSummary
public typealias Event = Components.Schemas.EventEvent
public typealias CreateEvent = Components.Schemas.EventCreateEvent
public typealias EventPaginatedResponse = Components.Schemas.EventPaginatedResponse
public typealias NotificationResponse = Components.Schemas.NotificationResponse
public typealias NotificationUpdate = Components.Schemas.NotificationUpdate
public typealias AppriseResponse = Components.Schemas.NotificationAppriseResponse
public typealias AppriseUpdate = Components.Schemas.NotificationAppriseUpdate
public typealias NotificationDispatchRequest = Components.Schemas.NotificationDispatchRequest

// MARK: - Templates, Webhooks, Registries

public typealias Template = Components.Schemas.TemplateTemplate
public typealias RemoteTemplate = Components.Schemas.TemplateRemoteTemplate
public typealias TemplateContent = Components.Schemas.TemplateTemplateContent
public typealias TemplateRegistry = Components.Schemas.TemplateTemplateRegistry
public typealias RemoteRegistry = Components.Schemas.TemplateRemoteRegistry
public typealias CreateTemplateRequest = Components.Schemas.TemplateCreateRequest
public typealias UpdateTemplateRequest = Components.Schemas.TemplateUpdateRequest
public typealias DefaultTemplatesResponse = Components.Schemas.TemplateDefaultTemplatesResponse
public typealias SaveDefaultTemplatesRequest = Components.Schemas.TemplateSaveDefaultTemplatesRequest
public typealias CreateTemplateRegistryRequest = Components.Schemas.TemplateCreateRegistryRequest
public typealias UpdateTemplateRegistryRequest = Components.Schemas.TemplateUpdateRegistryRequest
public typealias TemplatePaginatedResponse = Components.Schemas.TemplatePaginatedResponse
public typealias WebhookCreateInput = Components.Schemas.WebhookCreateInput
public typealias WebhookCreated = Components.Schemas.WebhookCreated
public typealias WebhookSummary = Components.Schemas.WebhookSummary
public typealias WebhookUpdateInput = Components.Schemas.WebhookUpdateInput
public typealias ContainerRegistry = Components.Schemas.ContainerregistryContainerRegistry
public typealias ContainerRegistryCredential = Components.Schemas.ContainerregistryCredential
public typealias ContainerRegistryPullUsage = Components.Schemas.ContainerregistryPullUsage
public typealias ContainerRegistryPullUsageResponse = Components.Schemas.ContainerregistryPullUsageResponse
public typealias ContainerRegistrySync = Components.Schemas.ContainerregistrySync
public typealias ContainerRegistrySyncRequest = Components.Schemas.ContainerregistrySyncRequest
public typealias ContainerRegistryPaginatedResponse = Components.Schemas.ContainerRegistryPaginatedResponse

// MARK: - Vulnerabilities, Updater, Jobs, Misc

public typealias Vulnerability = Components.Schemas.VulnerabilityVulnerability
public typealias VulnerabilityWithImage = Components.Schemas.VulnerabilityVulnerabilityWithImage
public typealias CVSSInfo = Components.Schemas.VulnerabilityCVSSInfo
public typealias SeveritySummary = Components.Schemas.VulnerabilitySeveritySummary
public typealias EnvironmentVulnerabilitySummary = Components.Schemas.VulnerabilityEnvironmentVulnerabilitySummary
public typealias VulnerabilityScanResult = Components.Schemas.VulnerabilityScanResult
public typealias VulnerabilityScanSummary = Components.Schemas.VulnerabilityScanSummary
public typealias VulnerabilityScanSummariesRequest = Components.Schemas.VulnerabilityScanSummariesRequest
public typealias VulnerabilityScanSummariesResponse = Components.Schemas.VulnerabilityScanSummariesResponse
public typealias VulnerabilityIgnorePayload = Components.Schemas.VulnerabilityIgnorePayload
public typealias IgnoredVulnerability = Components.Schemas.VulnerabilityIgnoredVulnerability
public typealias UpdaterOptions = Components.Schemas.UpdaterOptions
public typealias UpdaterResourceResult = Components.Schemas.UpdaterResourceResult
public typealias UpdaterResult = Components.Schemas.UpdaterResult
public typealias UpdaterStatus = Components.Schemas.UpdaterStatus
public typealias AutoUpdateRecord = Components.Schemas.AutoUpdateRecord
public typealias JobScheduleConfig = Components.Schemas.JobscheduleConfig
public typealias JobScheduleUpdate = Components.Schemas.JobscheduleUpdate
public typealias JobStatus = Components.Schemas.JobscheduleJobStatus
public typealias JobPrerequisite = Components.Schemas.JobscheduleJobPrerequisite
public typealias JobListResponse = Components.Schemas.JobscheduleJobListResponse
public typealias JobRunResponse = Components.Schemas.JobscheduleJobRunResponse
public typealias PortMapping = Components.Schemas.PortPortMapping
public typealias Category = Components.Schemas.CategoryCategory
public typealias DockerInfo = Components.Schemas.DockerinfoInfo
public typealias VersionInfo = Components.Schemas.VersionInfo
public typealias VersionCheck = Components.Schemas.VersionCheck
