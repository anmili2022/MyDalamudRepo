﻿﻿# MyDalamudRepo 更新速查

这个仓库提供 Dalamud 插件订阅源：

`https://raw.githubusercontent.com/anmili2022/MyDalamudRepo/main/pluginmaster.json`

详细说明看 `README.md`，这里保留一份适合下次快速更新的速查版。

## 当前维护的插件

1. `DalamudACT`
2. `PluginDockStandalone`
3. `PartyIcons`
4. `Saucy`
5. `StarlightBreaker`
6. `WondrousTailsSolver`

---

## 最快更新流程

### 1. 进入仓库并对齐远端

```powershell
cd E:\git\MyDalamudRepo
git fetch origin main
git rebase origin/main
```

### 2. 跑同步脚本

```powershell
$env:GITHUB_TOKEN = gh auth token
.\scripts\sync-pluginmaster.ps1
```

### 3. 更新后检查

```powershell
git status --short --untracked-files=all
git diff --stat
```

建议用 Python 验证关键版本，避免 PowerShell 控制台编码干扰：

```powershell
python --% -c "import json; from pathlib import Path; p=Path(r'E:\git\MyDalamudRepo\pluginmaster.json'); obj=json.loads(p.read_text(encoding='utf-8')); print('\n'.join('{} {}'.format(i.get('InternalName'), i.get('AssemblyVersion')) for i in obj if i.get('InternalName') in ('DalamudACT', 'WondrousTailsSolver')))"
```

### 4. 提交并推送

```powershell
git add -- pluginmaster.json scripts/sync-pluginmaster.ps1 README.md UPDATE.md
git commit -m "chore: sync pluginmaster to latest releases"
git push origin main
```

---

## 如果 push 被拒绝

先重新同步，再跑一次脚本：

```powershell
git fetch origin main
git rebase origin/main
$env:GITHUB_TOKEN = gh auth token
.\scripts\sync-pluginmaster.ps1
```

然后重新提交：

```powershell
git add -- pluginmaster.json scripts/sync-pluginmaster.ps1 README.md UPDATE.md
git commit -m "chore: sync pluginmaster to latest releases"
git push origin main
```

---

## 防乱码规则

### 1. `scripts/sync-pluginmaster.ps1` 必须保持 UTF-8 with BOM

这是最重要的一条。

如果脚本被保存成 UTF-8 无 BOM，Windows PowerShell 5.1 很容易把中文覆盖文案读坏，最后把乱码写进 `pluginmaster.json`。

### 2. 不要靠 PowerShell 控制台肉眼判断中文是否正常

更稳的方式是用 Python 按 UTF-8 读取：

```powershell
python --% -c "import json; from pathlib import Path; p=Path(r'E:\git\MyDalamudRepo\pluginmaster.json'); obj=json.loads(p.read_text(encoding='utf-8')); print('\n'.join('{}\n{}'.format(i['Description'], i['Punchline']) for i in obj if i.get('InternalName') == 'DalamudACT'))"
```

### 3. 优先跑脚本，不手改 `pluginmaster.json`

只要插件有上游 Release，就优先跑：

```powershell
.\scripts\sync-pluginmaster.ps1
```

这样更新更快，也不容易漏字段。

---

## 手动更新场景

如果某个插件没有可直接使用的上游 Release，流程如下：

1. 拉取插件源码
2. 本地编译 Release
3. 确认产物包含 `dll`、`deps.json`、插件 `json`、`zip`
4. 把 zip 放到本仓库对应目录
5. 更新 `pluginmaster.json` 里的版本号和下载链接
6. 再按上面的检查、提交、推送流程处理

---

## 记住这 3 条就够了

1. **先 rebase，再同步**
2. **同步脚本保持 UTF-8 with BOM**
3. **版本和中文用 Python 验证，不靠控制台猜**
