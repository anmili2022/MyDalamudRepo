Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pluginMasterPath = Join-Path $repoRoot "pluginmaster.json"
$defaultBranchCache = @{}
$githubHeaders = @{
    "Accept" = "application/vnd.github+json"
    "User-Agent" = "MyDalamudRepoSync"
}

if ($env:GITHUB_TOKEN) {
    $githubHeaders["Authorization"] = "Bearer $($env:GITHUB_TOKEN)"
}

$trackedPlugins = @(
    @{
        Repo = "anmili2022/StarlightBreaker"
        InternalName = "StarlightBreaker"
        ManifestKind = "releaseAssetJson"
        ManifestAssetPattern = "StarlightBreaker.json"
        ZipAssetPattern = "StarlightBreaker-*.zip"
        IconUrl = "https://raw.githubusercontent.com/anmili2022/StarlightBreaker/main/StarlightBreaker.Dalamud/icon.png"
        Overrides = @{
            Punchline = "关闭屏蔽词过滤，并高亮聊天和招募板里的屏蔽词。 Disable word-filter blocking and highlight filtered words in chat and Party Finder."
            Description = "关闭屏蔽词过滤，并特殊显示聊天频道或招募板发出的屏蔽词。 Disable word-filter blocking and specially highlight filtered words from chat channels or the Party Finder."
        }
    },
    @{
        Repo = "anmili2022/PluginDockStandalone"
        InternalName = "PluginDockStandalone"
        ManifestKind = "repoYaml"
        ManifestPath = "PluginDockStandalone.yaml"
        VersionPath = "PluginDockStandalone.csproj"
        ZipAssetPattern = "*.zip"
        IconUrl = "https://raw.githubusercontent.com/anmili2022/PluginDockStandalone/main/images/icon.png"
        DalamudApiLevel = 15
        Overrides = @{
            Name = "Plugin Dock Standalone"
            Punchline = "把常用插件入口收纳成可折叠的悬浮图标栏。 Collect common plugin entry points into a collapsible floating icon dock."
            Description = "把常用 Dalamud 插件的主界面和设置入口收纳到一个可折叠的悬浮图标栏里，并提供可配置布局与快捷访问。 Collect common Dalamud plugin entry points into a collapsible floating icon dock with configurable layout and quick access."
        }
    },
    @{
        Repo = "anmili2022/SaucyCN"
        InternalName = "Saucy"
        ManifestKind = "repoJson"
        ManifestPath = "Saucy/Saucy.json"
        VersionPath = "Saucy/Saucy.csproj"
        ZipAssetPattern = "*.zip"
        IconUrl = "https://raw.githubusercontent.com/anmili2022/SaucyCN/main/Saucy/Icon.png"
        Overrides = @{
            Punchline = "当刷 MGP 太费劲时的自动化帮手。 When working for MGP is too much effort."
            Description = "自动化处理部分金碟小游戏。 Automates certain Gold Saucer mini-games."
        }
    },
    @{
        Repo = "anmili2022/xivPartyIcons"
        InternalName = "PartyIcons"
        ManifestKind = "repoJson"
        ManifestPath = "PartyIcons/PartyIcons.json"
        VersionPath = "PartyIcons/PartyIcons.csproj"
        ZipAssetPattern = "*.zip"
        IconUrl = "https://raw.githubusercontent.com/anmili2022/xivPartyIcons/main/PartyIcons/Resources/icon.png"
        Overrides = @{
            Name = "Party Icons"
            Punchline = "用职业图标、团队站位等替换队友名字显示。 Replace names with job icons, raid role positions, and more."
            Description = "按当前内容调整玩家名牌显示，例如显示职业图标、自动分配的团队站位，或名字加职业图标。 Adjusts player nameplates based on current content, for example by showing job icons, automatically assigned raid positions, or names with job icons."
        }
    },
    @{
        Repo = "anmili2022/DalamudACT"
        InternalName = "DalamudACT"
        ManifestKind = "repoJson"
        ManifestPath = "DalamudACT/DalamudACT.json"
        VersionPath = "DalamudACT/DalamudACT.csproj"
        ZipAssetPattern = "DalamudACT.zip"
        Overrides = @{
            Name = "DalamudACT"
            Punchline = "在游戏内直接查看 ACTX 风格战斗统计。 Local ACTX-style combat stats directly inside the game."
            Description = "一个基于本地 ACTX 风格口径的 Dalamud 战斗统计插件，直接在游戏内显示队伍 DPS、HPS、承伤、概览和战斗历史，不依赖外部网页悬浮窗。 Local ACTX-style combat meter for Dalamud. Displays party DPS, HPS, damage taken, overview summaries, and encounter history directly in game without relying on an external web overlay."
        }
    }
)

$preferredFieldOrder = @(
    "Author",
    "Name",
    "InternalName",
    "AssemblyVersion",
    "TestingAssemblyVersion",
    "Description",
    "Punchline",
    "ApplicableVersion",
    "RepoUrl",
    "Tags",
    "CategoryTags",
    "DalamudApiLevel",
    "LoadRequiredState",
    "LoadSync",
    "CanUnloadAsync",
    "LoadPriority",
    "IconUrl",
    "ImageUrls",
    "AcceptsFeedback",
    "IsHide",
    "IsTestingExclusive",
    "DownloadLinkInstall",
    "DownloadLinkTesting",
    "DownloadLinkUpdate",
    "DownloadCount",
    "LastUpdated",
    "ChangeLog"
)

function Get-StatusCode {
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord] $ErrorRecord
    )

    $response = $ErrorRecord.Exception.Response
    if ($null -eq $response) {
        return $null
    }

    if ($response.PSObject.Properties["StatusCode"]) {
        return [int]$response.StatusCode
    }

    return $null
}

function ConvertTo-PlainData {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [string] -or
        $InputObject -is [bool] -or
        $InputObject -is [int] -or
        $InputObject -is [long] -or
        $InputObject -is [double] -or
        $InputObject -is [decimal]) {
        return $InputObject
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            $result[[string]$key] = ConvertTo-PlainData -InputObject $InputObject[$key]
        }

        return $result
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $items = New-Object System.Collections.Generic.List[object]
        foreach ($item in $InputObject) {
            $items.Add((ConvertTo-PlainData -InputObject $item))
        }

        return @($items)
    }

    $properties = @($InputObject.PSObject.Properties)
    if ($properties.Count -eq 0) {
        return $InputObject
    }

    $result = [ordered]@{}
    foreach ($property in $properties) {
        $result[$property.Name] = ConvertTo-PlainData -InputObject $property.Value
    }

    return $result
}

function Invoke-GitHubJsonApi {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Uri
    )

    return Invoke-RestMethod -Headers $githubHeaders -Uri $Uri
}

function Get-LatestRelease {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Repo
    )

    try {
        return Invoke-GitHubJsonApi -Uri "https://api.github.com/repos/$Repo/releases/latest"
    }
    catch {
        $statusCode = Get-StatusCode -ErrorRecord $_
        if ($statusCode -eq 404) {
            return $null
        }

        throw
    }
}

function Get-DefaultBranch {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Repo
    )

    if (-not $defaultBranchCache.ContainsKey($Repo)) {
        $repoInfo = Invoke-GitHubJsonApi -Uri "https://api.github.com/repos/$Repo"
        $defaultBranchCache[$Repo] = [string]$repoInfo.default_branch
    }

    return $defaultBranchCache[$Repo]
}

function Get-TextFromUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Uri
    )

    $response = Invoke-WebRequest -Headers $githubHeaders -Uri $Uri
    if ($response.Content -is [byte[]]) {
        return [System.Text.Encoding]::UTF8.GetString($response.Content)
    }

    return [string]$response.Content
}

function Get-RawContentWithFallback {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Repo,

        [Parameter(Mandatory = $true)]
        [string] $PreferredRef,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $refs = @($PreferredRef, (Get-DefaultBranch -Repo $Repo)) | Select-Object -Unique

    foreach ($ref in $refs) {
        $uri = "https://raw.githubusercontent.com/$Repo/$ref/$Path"
        try {
            return Get-TextFromUrl -Uri $uri
        }
        catch {
            $statusCode = Get-StatusCode -ErrorRecord $_
            if ($statusCode -eq 404) {
                continue
            }

            throw
        }
    }

    throw "Unable to fetch '$Path' from $Repo using refs: $($refs -join ', ')."
}

function ConvertFrom-SimpleYamlManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $lines = $Text -split "`r?`n"
    $data = @{}
    $index = 0

    while ($index -lt $lines.Count) {
        $line = $lines[$index]

        if ($line -match '^([A-Za-z_]+):\s*\|-\s*$') {
            $key = $Matches[1]
            $index++
            $block = New-Object System.Collections.Generic.List[string]

            while ($index -lt $lines.Count -and $lines[$index] -match '^\s{2}(.*)$') {
                $block.Add($Matches[1])
                $index++
            }

            $data[$key] = ($block -join "`n").TrimEnd()
            continue
        }

        if ($line -match '^([A-Za-z_]+):\s*$') {
            $key = $Matches[1]
            $index++
            $items = New-Object System.Collections.Generic.List[string]

            while ($index -lt $lines.Count -and $lines[$index] -match '^\s{2}-\s*(.*)$') {
                $items.Add($Matches[1])
                $index++
            }

            $data[$key] = @($items)
            continue
        }

        if ($line -match '^([A-Za-z_]+):\s*(.*)$') {
            $data[$Matches[1]] = $Matches[2].Trim()
        }

        $index++
    }

    return $data
}

function Get-ProjectVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Repo,

        [Parameter(Mandatory = $true)]
        [string] $PreferredRef,

        [Parameter(Mandatory = $true)]
        [string] $ProjectPath
    )

    [xml] $project = Get-RawContentWithFallback -Repo $Repo -PreferredRef $PreferredRef -Path $ProjectPath

    foreach ($propertyGroup in @($project.Project.PropertyGroup)) {
        foreach ($field in @("AssemblyVersion", "Version", "FileVersion")) {
            $value = $propertyGroup.$field | Select-Object -First 1
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return [string]$value
            }
        }
    }

    throw "Unable to find a version in $Repo/$ProjectPath."
}

function Get-ReleaseAsset {
    param(
        [Parameter(Mandatory = $true)]
        $Release,

        [Parameter(Mandatory = $true)]
        [string] $Pattern
    )

    $asset = @($Release.assets | Where-Object { $_.name -like $Pattern }) | Select-Object -First 1
    if ($null -eq $asset) {
        throw "Release '$($Release.tag_name)' is missing an asset matching '$Pattern'."
    }

    return $asset
}

function Get-ReleaseManifest {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $PluginConfig,

        [Parameter(Mandatory = $true)]
        $Release
    )

    switch ($PluginConfig.ManifestKind) {
        "releaseAssetJson" {
            $asset = Get-ReleaseAsset -Release $Release -Pattern $PluginConfig.ManifestAssetPattern
            return ConvertTo-PlainData -InputObject ((Get-TextFromUrl -Uri $asset.browser_download_url) | ConvertFrom-Json)
        }
        "repoJson" {
            $json = Get-RawContentWithFallback -Repo $PluginConfig.Repo -PreferredRef $Release.tag_name -Path $PluginConfig.ManifestPath
            return ConvertTo-PlainData -InputObject ($json | ConvertFrom-Json)
        }
        "repoYaml" {
            $yaml = Get-RawContentWithFallback -Repo $PluginConfig.Repo -PreferredRef $Release.tag_name -Path $PluginConfig.ManifestPath
            $manifest = ConvertFrom-SimpleYamlManifest -Text $yaml
            return [ordered]@{
                Author = $manifest.author
                Name = $manifest.name
                InternalName = $PluginConfig.InternalName
                Description = $manifest.description
                Punchline = $manifest.punchline
                RepoUrl = "https://github.com/$($PluginConfig.Repo)"
                IconUrl = $PluginConfig.IconUrl
                Tags = $manifest.tags
                CategoryTags = $manifest.category_tags
                ApplicableVersion = "any"
                AcceptsFeedback = $true
                DalamudApiLevel = $PluginConfig.DalamudApiLevel
            }
        }
        default {
            throw "Unsupported manifest kind '$($PluginConfig.ManifestKind)'."
        }
    }
}

function New-OrderedPluginEntry {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Source
    )

    $entry = [ordered]@{}
    foreach ($field in $preferredFieldOrder) {
        if ($Source.Contains($field) -and $null -ne $Source[$field]) {
            $entry[$field] = $Source[$field]
        }
    }

    foreach ($field in $Source.Keys) {
        if ($entry.Contains($field) -or $null -eq $Source[$field]) {
            continue
        }

        $entry[$field] = $Source[$field]
    }

    return $entry
}

function New-PluginEntryFromRelease {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $PluginConfig,

        [Parameter(Mandatory = $true)]
        $Release
    )

    $manifest = Get-ReleaseManifest -PluginConfig $PluginConfig -Release $Release
    $manifest["InternalName"] = $PluginConfig.InternalName
    $manifest["RepoUrl"] = "https://github.com/$($PluginConfig.Repo)"
    $manifest["ApplicableVersion"] = "any"

    if ($PluginConfig.ContainsKey("IconUrl")) {
        $manifest["IconUrl"] = $PluginConfig.IconUrl
    }

    if ($PluginConfig.ContainsKey("Overrides")) {
        foreach ($key in $PluginConfig.Overrides.Keys) {
            $manifest[$key] = $PluginConfig.Overrides[$key]
        }
    }

    if ($PluginConfig.ContainsKey("VersionPath")) {
        $manifest["AssemblyVersion"] = Get-ProjectVersion -Repo $PluginConfig.Repo -PreferredRef $Release.tag_name -ProjectPath $PluginConfig.VersionPath
    }
    elseif (-not $manifest.Contains("AssemblyVersion")) {
        throw "Plugin '$($PluginConfig.InternalName)' does not expose an AssemblyVersion."
    }

    if (-not $manifest.Contains("AcceptsFeedback")) {
        $manifest["AcceptsFeedback"] = $true
    }

    $zipAsset = Get-ReleaseAsset -Release $Release -Pattern $PluginConfig.ZipAssetPattern
    $manifest["DownloadLinkInstall"] = $zipAsset.browser_download_url
    $manifest["DownloadLinkUpdate"] = $zipAsset.browser_download_url

    return New-OrderedPluginEntry -Source $manifest
}

function Read-PluginmasterEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $entries = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path $Path)) {
        return $entries
    }

    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        $parsed = @($content | ConvertFrom-Json)
        foreach ($item in $parsed) {
            $entries.Add((ConvertTo-PlainData -InputObject $item))
        }
    }
    catch {
        Write-Warning "Existing pluginmaster.json is invalid; rebuilding it from tracked releases."
    }

    return $entries
}

function Write-Utf8NoBomFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

$entries = Read-PluginmasterEntries -Path $pluginMasterPath

foreach ($plugin in $trackedPlugins) {
    $release = Get-LatestRelease -Repo $plugin.Repo
    if ($null -eq $release) {
        Write-Host "No published release found for $($plugin.Repo); leaving current entry unchanged."
        continue
    }

    $entry = New-PluginEntryFromRelease -PluginConfig $plugin -Release $release
    $currentIndex = -1

    for ($i = 0; $i -lt $entries.Count; $i++) {
        if ($entries[$i].InternalName -eq $plugin.InternalName) {
            $currentIndex = $i
            break
        }
    }

    if ($currentIndex -ge 0) {
        $entries[$currentIndex] = $entry
        Write-Host "Updated $($plugin.InternalName) to $($entry.AssemblyVersion)."
    }
    else {
        $entries.Add($entry)
        Write-Host "Added $($plugin.InternalName) at $($entry.AssemblyVersion)."
    }
}

$sortedEntries = @($entries | Sort-Object -Property InternalName)
$json = $sortedEntries | ConvertTo-Json -Depth 20
$json = $json.TrimEnd() + [Environment]::NewLine

Write-Utf8NoBomFile -Path $pluginMasterPath -Content $json
