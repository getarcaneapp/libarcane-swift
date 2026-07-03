import Foundation

/// PublicSetting is a publicly accessible setting value.
public struct PublicSetting: Codable, Hashable, Sendable, Identifiable {
  public var key: String
  public var type: String
  public var value: String

  public var id: String { key }

  public init(key: String, type: String, value: String) {
    self.key = key
    self.type = type
    self.value = value
  }
}

/// SettingDto is a setting value with visibility metadata.
public struct SettingDto: Codable, Hashable, Sendable, Identifiable {
  public var key: String
  public var type: String
  public var value: String
  public var isPublic: Bool

  public var id: String { key }

  public init(key: String, type: String, value: String, isPublic: Bool) {
    self.key = key
    self.type = type
    self.value = value
    self.isPublic = isPublic
  }
}

/// UpdateSettings is the request body for ``PUT /environments/{id}/settings``.
///
/// All fields are optional strings — only the fields you set are updated.
public struct UpdateSettings: Codable, Hashable, Sendable {
  public var projectsDirectory: String?
  public var followProjectSymlinks: String?
  public var swarmStackSourcesDirectory: String?
  public var diskUsagePath: String?
  public var autoUpdate: String?
  public var autoUpdateInterval: String?
  public var pollingEnabled: String?
  public var pollingInterval: String?
  public var dockerClientRefreshInterval: String?
  public var autoInjectEnv: String?
  public var environmentHealthInterval: String?
  public var dockerPruneMode: String?
  public var defaultDeployPullPolicy: String?
  public var scheduledPruneEnabled: String?
  public var scheduledPruneInterval: String?
  public var scheduledPruneContainers: String?
  public var scheduledPruneImages: String?
  public var scheduledPruneVolumes: String?
  public var scheduledPruneNetworks: String?
  public var scheduledPruneBuildCache: String?
  public var pruneContainerMode: String?
  public var pruneContainerUntil: String?
  public var pruneImageMode: String?
  public var pruneImageUntil: String?
  public var pruneVolumeMode: String?
  public var pruneNetworkMode: String?
  public var pruneNetworkUntil: String?
  public var pruneBuildCacheMode: String?
  public var pruneBuildCacheUntil: String?
  public var vulnerabilityScanEnabled: String?
  public var vulnerabilityScanInterval: String?
  public var maxImageUploadSize: String?
  public var gitSyncMaxFiles: String?
  public var gitSyncMaxTotalSizeMb: String?
  public var gitSyncMaxBinarySizeMb: String?
  public var baseServerUrl: String?
  public var enableGravatar: String?
  public var defaultShell: String?
  public var dockerHost: String?
  public var accentColor: String?
  public var applicationTheme: String?
  public var authLocalEnabled: String?
  public var oidcEnabled: String?
  public var oidcMergeAccounts: String?
  public var authSessionTimeout: String?
  public var authPasswordPolicy: String?
  public var trivyImage: String?
  public var trivyNetwork: String?
  public var trivySecurityOpts: String?
  public var trivyPrivileged: String?
  public var trivyPreserveCacheOnVolumePrune: String?
  public var trivyResourceLimitsEnabled: String?
  public var trivyCpuLimit: String?
  public var trivyMemoryLimitMb: String?
  public var trivyConcurrentScanContainers: String?
  public var authOidcConfig: String?
  public var oidcClientId: String?
  public var oidcClientSecret: String?
  public var oidcIssuerUrl: String?
  public var oidcScopes: String?
  public var oidcAdminClaim: String?
  public var oidcAdminValue: String?
  public var oidcSkipTlsVerify: String?
  public var oidcAutoRedirectToProvider: String?
  public var oidcProviderName: String?
  public var oidcProviderLogoUrl: String?
  public var mobileNavigationMode: String?
  public var mobileNavigationShowLabels: String?
  public var sidebarHoverExpansion: String?
  public var keyboardShortcutsEnabled: String?
  public var dockerApiTimeout: String?
  public var dockerImagePullTimeout: String?
  public var trivyScanTimeout: String?
  public var gitOperationTimeout: String?
  public var httpClientTimeout: String?
  public var registryTimeout: String?
  public var proxyRequestTimeout: String?
  public var autoUpdateExcludedContainers: String?
  public var autoHealEnabled: String?
  public var autoHealInterval: String?
  public var autoHealExcludedContainers: String?
  public var autoHealMaxRestarts: String?
  public var autoHealRestartWindow: String?
  public var buildProvider: String?
  public var buildsDirectory: String?
  public var buildTimeout: String?
  public var depotProjectId: String?
  public var depotToken: String?
  public var oledMode: String?

  // swiftlint:disable:next function_body_length
  public init(
    projectsDirectory: String? = nil,
    followProjectSymlinks: String? = nil,
    swarmStackSourcesDirectory: String? = nil,
    diskUsagePath: String? = nil,
    autoUpdate: String? = nil,
    autoUpdateInterval: String? = nil,
    pollingEnabled: String? = nil,
    pollingInterval: String? = nil,
    dockerClientRefreshInterval: String? = nil,
    autoInjectEnv: String? = nil,
    environmentHealthInterval: String? = nil,
    dockerPruneMode: String? = nil,
    defaultDeployPullPolicy: String? = nil,
    scheduledPruneEnabled: String? = nil,
    scheduledPruneInterval: String? = nil,
    scheduledPruneContainers: String? = nil,
    scheduledPruneImages: String? = nil,
    scheduledPruneVolumes: String? = nil,
    scheduledPruneNetworks: String? = nil,
    scheduledPruneBuildCache: String? = nil,
    pruneContainerMode: String? = nil,
    pruneContainerUntil: String? = nil,
    pruneImageMode: String? = nil,
    pruneImageUntil: String? = nil,
    pruneVolumeMode: String? = nil,
    pruneNetworkMode: String? = nil,
    pruneNetworkUntil: String? = nil,
    pruneBuildCacheMode: String? = nil,
    pruneBuildCacheUntil: String? = nil,
    vulnerabilityScanEnabled: String? = nil,
    vulnerabilityScanInterval: String? = nil,
    maxImageUploadSize: String? = nil,
    gitSyncMaxFiles: String? = nil,
    gitSyncMaxTotalSizeMb: String? = nil,
    gitSyncMaxBinarySizeMb: String? = nil,
    baseServerUrl: String? = nil,
    enableGravatar: String? = nil,
    defaultShell: String? = nil,
    dockerHost: String? = nil,
    accentColor: String? = nil,
    applicationTheme: String? = nil,
    authLocalEnabled: String? = nil,
    oidcEnabled: String? = nil,
    oidcMergeAccounts: String? = nil,
    authSessionTimeout: String? = nil,
    authPasswordPolicy: String? = nil,
    trivyImage: String? = nil,
    trivyNetwork: String? = nil,
    trivySecurityOpts: String? = nil,
    trivyPrivileged: String? = nil,
    trivyPreserveCacheOnVolumePrune: String? = nil,
    trivyResourceLimitsEnabled: String? = nil,
    trivyCpuLimit: String? = nil,
    trivyMemoryLimitMb: String? = nil,
    trivyConcurrentScanContainers: String? = nil,
    authOidcConfig: String? = nil,
    oidcClientId: String? = nil,
    oidcClientSecret: String? = nil,
    oidcIssuerUrl: String? = nil,
    oidcScopes: String? = nil,
    oidcAdminClaim: String? = nil,
    oidcAdminValue: String? = nil,
    oidcSkipTlsVerify: String? = nil,
    oidcAutoRedirectToProvider: String? = nil,
    oidcProviderName: String? = nil,
    oidcProviderLogoUrl: String? = nil,
    mobileNavigationMode: String? = nil,
    mobileNavigationShowLabels: String? = nil,
    sidebarHoverExpansion: String? = nil,
    keyboardShortcutsEnabled: String? = nil,
    dockerApiTimeout: String? = nil,
    dockerImagePullTimeout: String? = nil,
    trivyScanTimeout: String? = nil,
    gitOperationTimeout: String? = nil,
    httpClientTimeout: String? = nil,
    registryTimeout: String? = nil,
    proxyRequestTimeout: String? = nil,
    autoUpdateExcludedContainers: String? = nil,
    autoHealEnabled: String? = nil,
    autoHealInterval: String? = nil,
    autoHealExcludedContainers: String? = nil,
    autoHealMaxRestarts: String? = nil,
    autoHealRestartWindow: String? = nil,
    buildProvider: String? = nil,
    buildsDirectory: String? = nil,
    buildTimeout: String? = nil,
    depotProjectId: String? = nil,
    depotToken: String? = nil,
    oledMode: String? = nil
  ) {
    self.projectsDirectory = projectsDirectory
    self.followProjectSymlinks = followProjectSymlinks
    self.swarmStackSourcesDirectory = swarmStackSourcesDirectory
    self.diskUsagePath = diskUsagePath
    self.autoUpdate = autoUpdate
    self.autoUpdateInterval = autoUpdateInterval
    self.pollingEnabled = pollingEnabled
    self.pollingInterval = pollingInterval
    self.dockerClientRefreshInterval = dockerClientRefreshInterval
    self.autoInjectEnv = autoInjectEnv
    self.environmentHealthInterval = environmentHealthInterval
    self.dockerPruneMode = dockerPruneMode
    self.defaultDeployPullPolicy = defaultDeployPullPolicy
    self.scheduledPruneEnabled = scheduledPruneEnabled
    self.scheduledPruneInterval = scheduledPruneInterval
    self.scheduledPruneContainers = scheduledPruneContainers
    self.scheduledPruneImages = scheduledPruneImages
    self.scheduledPruneVolumes = scheduledPruneVolumes
    self.scheduledPruneNetworks = scheduledPruneNetworks
    self.scheduledPruneBuildCache = scheduledPruneBuildCache
    self.pruneContainerMode = pruneContainerMode
    self.pruneContainerUntil = pruneContainerUntil
    self.pruneImageMode = pruneImageMode
    self.pruneImageUntil = pruneImageUntil
    self.pruneVolumeMode = pruneVolumeMode
    self.pruneNetworkMode = pruneNetworkMode
    self.pruneNetworkUntil = pruneNetworkUntil
    self.pruneBuildCacheMode = pruneBuildCacheMode
    self.pruneBuildCacheUntil = pruneBuildCacheUntil
    self.vulnerabilityScanEnabled = vulnerabilityScanEnabled
    self.vulnerabilityScanInterval = vulnerabilityScanInterval
    self.maxImageUploadSize = maxImageUploadSize
    self.gitSyncMaxFiles = gitSyncMaxFiles
    self.gitSyncMaxTotalSizeMb = gitSyncMaxTotalSizeMb
    self.gitSyncMaxBinarySizeMb = gitSyncMaxBinarySizeMb
    self.baseServerUrl = baseServerUrl
    self.enableGravatar = enableGravatar
    self.defaultShell = defaultShell
    self.dockerHost = dockerHost
    self.accentColor = accentColor
    self.applicationTheme = applicationTheme
    self.authLocalEnabled = authLocalEnabled
    self.oidcEnabled = oidcEnabled
    self.oidcMergeAccounts = oidcMergeAccounts
    self.authSessionTimeout = authSessionTimeout
    self.authPasswordPolicy = authPasswordPolicy
    self.trivyImage = trivyImage
    self.trivyNetwork = trivyNetwork
    self.trivySecurityOpts = trivySecurityOpts
    self.trivyPrivileged = trivyPrivileged
    self.trivyPreserveCacheOnVolumePrune = trivyPreserveCacheOnVolumePrune
    self.trivyResourceLimitsEnabled = trivyResourceLimitsEnabled
    self.trivyCpuLimit = trivyCpuLimit
    self.trivyMemoryLimitMb = trivyMemoryLimitMb
    self.trivyConcurrentScanContainers = trivyConcurrentScanContainers
    self.authOidcConfig = authOidcConfig
    self.oidcClientId = oidcClientId
    self.oidcClientSecret = oidcClientSecret
    self.oidcIssuerUrl = oidcIssuerUrl
    self.oidcScopes = oidcScopes
    self.oidcAdminClaim = oidcAdminClaim
    self.oidcAdminValue = oidcAdminValue
    self.oidcSkipTlsVerify = oidcSkipTlsVerify
    self.oidcAutoRedirectToProvider = oidcAutoRedirectToProvider
    self.oidcProviderName = oidcProviderName
    self.oidcProviderLogoUrl = oidcProviderLogoUrl
    self.mobileNavigationMode = mobileNavigationMode
    self.mobileNavigationShowLabels = mobileNavigationShowLabels
    self.sidebarHoverExpansion = sidebarHoverExpansion
    self.keyboardShortcutsEnabled = keyboardShortcutsEnabled
    self.dockerApiTimeout = dockerApiTimeout
    self.dockerImagePullTimeout = dockerImagePullTimeout
    self.trivyScanTimeout = trivyScanTimeout
    self.gitOperationTimeout = gitOperationTimeout
    self.httpClientTimeout = httpClientTimeout
    self.registryTimeout = registryTimeout
    self.proxyRequestTimeout = proxyRequestTimeout
    self.autoUpdateExcludedContainers = autoUpdateExcludedContainers
    self.autoHealEnabled = autoHealEnabled
    self.autoHealInterval = autoHealInterval
    self.autoHealExcludedContainers = autoHealExcludedContainers
    self.autoHealMaxRestarts = autoHealMaxRestarts
    self.autoHealRestartWindow = autoHealRestartWindow
    self.buildProvider = buildProvider
    self.buildsDirectory = buildsDirectory
    self.buildTimeout = buildTimeout
    self.depotProjectId = depotProjectId
    self.depotToken = depotToken
    self.oledMode = oledMode
  }
}
