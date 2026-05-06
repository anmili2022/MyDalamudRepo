# MyDalamudRepo 更新说明

这个仓库目前提供的库链地址：

`https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/pluginmaster.json`

## 当前插件

当前 `pluginmaster.json` 维护这 6 个插件：

1. `DalamudACT`
2. `PluginDockStandalone`
3. `PartyIcons`
4. `Saucy`
5. `StarlightBreaker`
6. `WondrousTailsSolver`

## 两种更新方式

这个仓库的插件分两类维护：

1. 有上游 GitHub Release 的插件
2. 没有上游 GitHub Release、由本仓库托管 zip 的插件

### 1. 有上游 Release 的插件

这类插件由 GitHub Actions 自动检查和更新。

当前按这个方式维护的插件：

1. `DalamudACT`
2. `PluginDockStandalone`
3. `Saucy`
4. `StarlightBreaker`

更新方法：

1. 打开 GitHub 仓库 `anmili2022/MyDalamudRepo`
2. 进入 `Actions`
3. 运行工作流 `Sync Pluginmaster`
4. 或等待它按计划自动运行

工作流文件：

`/.github/workflows/sync-pluginmaster.yml`

同步脚本：

`/scripts/sync-pluginmaster.ps1`

脚本会做这些事：

1. 检查上游仓库是否出现新的 release
2. 读取上游插件清单和版本号
3. 自动更新 `pluginmaster.json`
4. 如果有变更，自动提交到 `main`

### 2. 本仓库托管 zip 的插件

这类插件上游暂时没有正式 GitHub Release，所以需要手动更新。

当前按这个方式维护的插件：

1. `PartyIcons`
2. `WondrousTailsSolver`

更新方法：

1. 拉取插件源码仓库最新代码
2. 本地编译插件
3. 确认产出 `dll`、`deps.json`、插件 `json`、图标和 `zip`
4. 把新的 zip 放到 `/packages/`
5. 更新 `pluginmaster.json` 里的版本和下载链接
6. 提交并推送到 GitHub

## 手动更新详细步骤

以本仓库托管 zip 的插件为例：

1. 进入对应源码目录
2. 执行 `dotnet restore`
3. 执行 `dotnet build -c Release`
4. 找到产出的 zip
5. 把 zip 复制到 `MyDalamudRepo/packages/`
6. 修改 `pluginmaster.json` 中对应插件的：
   `AssemblyVersion`
7. 修改 `pluginmaster.json` 中对应插件的：
   `DownloadLinkInstall`
8. 修改 `pluginmaster.json` 中对应插件的：
   `DownloadLinkUpdate`
9. 如果文案变了，同时修改：
   `Description`
10. 如果文案变了，同时修改：
   `Punchline`
11. 提交并推送

提交命令：

```powershell
git add pluginmaster.json packages scripts
git commit -m "Update plugin feed"
git push origin main
```

## 新增一个插件时怎么做

### 情况 A：上游已经有 Release

1. 在 `/scripts/sync-pluginmaster.ps1` 里新增一个插件配置
2. 配好：
   `Repo`
3. 配好：
   `InternalName`
4. 配好：
   `ManifestKind`
5. 配好：
   `ManifestAssetPattern` 或 `ManifestPath`
6. 配好：
   `ZipAssetPattern`
7. 配好：
   `IconUrl`
8. 如果需要双语覆盖文案，增加：
   `Overrides`
9. 提交后运行 `Sync Pluginmaster`

### 情况 B：上游没有 Release

1. 先本地构建插件 zip
2. 把 zip 放进 `/packages/`
3. 手动把插件条目加进 `pluginmaster.json`
4. 下载地址指向本仓库的 raw zip
5. 提交并推送

下载地址格式示例：

`https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/packages/PluginName-Version.zip`

## 更新后怎么确认

更新后检查这两个地址：

1. 库链 JSON
   `https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/pluginmaster.json`
2. 对应插件 zip
   `https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/packages/...`

如果 `raw` 暂时看到旧内容，可能是缓存。可以临时这样测试：

`https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/pluginmaster.json?cachebust=test`

## 文案规则

当前 `Description` 和 `Punchline` 统一使用：

中文在前，英文在后

例如：

`在游戏内直接查看 ACTX 风格战斗统计。 Local ACTX-style combat stats directly inside the game.`

如果你手动改了 `pluginmaster.json`，也要同步改 `/scripts/sync-pluginmaster.ps1` 里的 `Overrides`，否则自动同步时会把文案覆盖回去。

## 常见问题

### 为什么线上 raw 还是旧的

常见原因：

1. 只改了本地，还没 `git push`
2. GitHub raw 缓存还没刷新
3. 工作流还没跑完

### 为什么插件没被自动加进去

常见原因：

1. 上游没有正式 release
2. release 里没有脚本预期的 zip 或 json 资产
3. `sync-pluginmaster.ps1` 里还没给这个插件写规则

### 为什么工作流没更新某个插件

先检查：

1. GitHub Release 页面是否真的出现了新版本
2. release 资产名是否和脚本里的匹配规则一致
3. 插件清单文件路径是否变化

## 相关文件

1. `/pluginmaster.json`
2. `/.github/workflows/sync-pluginmaster.yml`
3. `/scripts/sync-pluginmaster.ps1`
4. `/packages/`
