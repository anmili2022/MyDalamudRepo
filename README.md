# MyDalamudRepo

这个仓库提供 Dalamud 插件订阅源：

`https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/pluginmaster.json`

如果你只想快速更新，先看 `UPDATE.md`；这里保留完整说明和防乱码细节。

## 当前维护的插件

当前 `pluginmaster.json` 维护这些插件：

1. `DalamudACT`
2. `PluginDockStandalone`
3. `PartyIcons`
4. `Saucy`
5. `StarlightBreaker`
6. `WondrousTailsSolver`

---

# 下次更新的最快流程

目标：

- 尽量少手动改文件
- 尽量减少和远端冲突
- 尽量避免中文乱码

## 1. 进入仓库

```powershell
cd E:\git\MyDalamudRepo
```

## 2. 先同步远端

每次更新前，先把本地分支和远端 `main` 对齐，避免 `pluginmaster.json` 冲突。

```powershell
git fetch origin main
git rebase origin/main
```

## 3. 跑同步脚本

```powershell
$env:GITHUB_TOKEN = gh auth token
.\scripts\sync-pluginmaster.ps1
```

这个脚本会自动：

1. 检查上游仓库最新 Release
2. 拉取 manifest / 版本号 / zip 下载链接
3. 更新 `pluginmaster.json`
4. 按 `InternalName` 排序输出

## 4. 更新后验证

### 看改动

```powershell
git status --short --untracked-files=all
git diff --stat
```

### 验证关键插件版本

建议用 Python 检查，避免 PowerShell 编码干扰：

```powershell
python --% -c "import json; from pathlib import Path; p=Path(r'E:\git\MyDalamudRepo\pluginmaster.json'); obj=json.loads(p.read_text(encoding='utf-8')); print('\n'.join('{} {}'.format(i.get('InternalName'), i.get('AssemblyVersion')) for i in obj if i.get('InternalName') in ('DalamudACT', 'WondrousTailsSolver')))"
```

## 5. 提交并推送

```powershell
git add -- pluginmaster.json scripts/sync-pluginmaster.ps1 README.md UPDATE.md
git commit -m "chore: sync pluginmaster to latest releases"
git push origin main
```

---

# 如果 push 被拒绝

如果出现远端先更新、导致 `push` 被拒绝：

```powershell
git fetch origin main
git rebase origin/main
```

然后重新跑一次同步脚本：

```powershell
$env:GITHUB_TOKEN = gh auth token
.\scripts\sync-pluginmaster.ps1
```

再重新提交推送：

```powershell
git add -- pluginmaster.json scripts/sync-pluginmaster.ps1 README.md UPDATE.md
git commit -m "chore: sync pluginmaster to latest releases"
git push origin main
```

---

# 防乱码规范（重要）

这部分是以后更新速度快、又不容易出乱码的关键。

## 1. `scripts/sync-pluginmaster.ps1` 必须保持 UTF-8 with BOM

这个脚本里有中文覆盖文案。

如果本地用的是 Windows PowerShell 5.1，而脚本又是 **UTF-8 无 BOM**，很容易把中文读坏，最后把乱码写进 `pluginmaster.json`。

所以以后：

- 可以改脚本内容
- 但不要把它保存成 **UTF-8 无 BOM**
- 必须保持 **UTF-8 with BOM**

## 2. 尽量不要用 PowerShell 控制台肉眼判断中文是否正常

PowerShell 控制台显示乱码，不一定代表文件真的坏了。

更稳的方式是用 Python 按 UTF-8 读取：

```powershell
python --% -c "import json; from pathlib import Path; p=Path(r'E:\git\MyDalamudRepo\pluginmaster.json'); obj=json.loads(p.read_text(encoding='utf-8')); print('\n'.join('{}\n{}'.format(i['Description'], i['Punchline']) for i in obj if i.get('InternalName') == 'DalamudACT'))"
```

## 3. 优先让脚本生成，不手改 `pluginmaster.json`

只要上游是 Release 型插件，优先跑：

```powershell
.\scripts\sync-pluginmaster.ps1
```

而不是直接手改 `pluginmaster.json`。

这样：

- 更新更快
- 字段更统一
- 不容易漏版本号和下载链接

## 4. 改完后再检查远端 raw 地址

推送完成后，可以直接看订阅源是否已经生效：

```powershell
$url = 'https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/pluginmaster.json'
(Invoke-WebRequest -Uri $url -Headers @{ "User-Agent" = "PowerShell" }).StatusCode
```

如果要看关键版本号是否生效，也建议用 Python 从远端读：

```powershell
python --% -c "import json, urllib.request; url='https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/pluginmaster.json'; text=urllib.request.urlopen(url).read().decode('utf-8'); obj=json.loads(text); print('\n'.join('{} {}'.format(i.get('InternalName'), i.get('AssemblyVersion')) for i in obj if i.get('InternalName') in ('DalamudACT', 'WondrousTailsSolver')))"
```

---

# 手动更新场景

如果某个插件没有可直接使用的上游 Release，需要手动处理时，流程如下：

1. 拉取插件源码
2. 本地编译 Release
3. 确认产物包含：
   - `dll`
   - `deps.json`
   - 插件 `json`
   - `zip`
4. 把 zip 放进本仓库对应目录
5. 更新 `pluginmaster.json` 中对应插件的：
   - `AssemblyVersion`
   - `DownloadLinkInstall`
   - `DownloadLinkUpdate`
   - 必要时的 `Description`
   - 必要时的 `Punchline`
6. 再按上面的验证和提交流程处理

---

# 当前建议

以后日常更新，最省事的顺序就是：

```powershell
cd E:\git\MyDalamudRepo
git fetch origin main
git rebase origin/main
$env:GITHUB_TOKEN = gh auth token
.\scripts\sync-pluginmaster.ps1
git status --short --untracked-files=all
git diff --stat
git add -- pluginmaster.json scripts/sync-pluginmaster.ps1 README.md UPDATE.md
git commit -m "chore: sync pluginmaster to latest releases"
git push origin main
```

如果只记 3 条，就记这三条：

1. **先 rebase，再同步**
2. **同步脚本保持 UTF-8 with BOM**
3. **验证版本和中文用 Python，不靠控制台肉眼猜**

