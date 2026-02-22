# Windows Terminal Oh-My-Posh 美化筆記

## 環境說明

- OS：Windows 10 / 11
- 適用：Windows PowerShell 5.1 + PowerShell 7

---

## Step 1：安裝 Windows Terminal

從 Microsoft Store 下載安裝 **Windows Terminal**。

---

## Step 2：安裝 PowerShell 7

```powershell
winget install Microsoft.PowerShell
```

安裝完後 Windows Terminal 通常會自動偵測並新增 PowerShell 7 的 profile。

---

## Step 3：安裝 oh-my-posh

以系統管理員執行 PowerShell，使用 winget 安裝：

```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget
```

> **注意：** 不要從 Microsoft Store 安裝 oh-my-posh，Store 版本不附帶主題檔案。
> 若已安裝 Store 版本，用 `--force` 重新安裝：
> ```powershell
> winget install JanDeDobbeleer.OhMyPosh -s winget --force
> ```

---

## Step 4：安裝字體

下載並安裝 **Meslo LGM NF** 字體（Nerd Font，oh-my-posh 主題需要此字體才能正確顯示圖示）。

下載來源：https://www.nerdfonts.com/font-downloads

---

## Step 5：下載主題檔案

oh-my-posh 主題需手動下載，以 `paradox` 主題為例：

```powershell
New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\oh-my-posh\themes" -Force

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json" -OutFile "$env:LOCALAPPDATA\oh-my-posh\themes\paradox.omp.json"
```

所有可用主題預覽：https://ohmyposh.dev/docs/themes

換其他主題只需把 URL 和檔名中的 `paradox` 替換即可。

---

## Step 6：安裝 posh-git

**Windows PowerShell 5.1：**

```powershell
Install-Module posh-git -Scope CurrentUser
```

**PowerShell 7（需另外安裝）：**

```powershell
Install-Module posh-git -Scope CurrentUser -Force
```

---

## Step 7：設定 $PROFILE

### PowerShell 7

開啟設定檔：

```powershell
if (!(Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force }
notepad $PROFILE
```

寫入以下內容：

```powershell
Import-Module posh-git
oh-my-posh init pwsh --config "$env:LOCALAPPDATA\oh-my-posh\themes\paradox.omp.json" | Invoke-Expression
```

### Windows PowerShell 5.1

開啟設定檔：

```powershell
if (!(Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force }
notepad $PROFILE
```

寫入以下內容（注意是 `init powershell`，不是 `init pwsh`）：

```powershell
Import-Module posh-git
oh-my-posh init powershell --config "$env:LOCALAPPDATA\oh-my-posh\themes\paradox.omp.json" | Invoke-Expression
```

---

## Step 8：設定 Windows Terminal

開啟 `settings.json`（Windows Terminal 右上角 `∨` → 設定 → 左下角「開啟 JSON 檔案」）。

在 `profiles.list` 中新增或修改以下 profile：

**PowerShell 7：**

```json
{
    "commandline": "%ProgramFiles%\\PowerShell\\7\\pwsh.exe",
    "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
    "hidden": false,
    "name": "PowerShell",
    "font":
    {
        "face": "MesloLGM NF"
    }
}
```

**Windows PowerShell 5.1：**

```json
{
    "commandline": "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
    "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
    "hidden": false,
    "name": "Windows PowerShell",
    "font":
    {
        "face": "MesloLGM NF"
    }
}
```

建議將預設 profile 改為 PowerShell 7：

```json
"defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
```

---

## Step 9：設定 VS Code 字體

開啟 VS Code，按 `Ctrl+Shift+P` → 搜尋 `Open User Settings (JSON)`，加入以下設定：

```json
// 編輯器字體（適合閱讀程式碼的字體）
"editor.fontFamily": "Cascadia Code, Consolas, monospace",
"editor.fontSize": 14,
"editor.fontLigatures": true,

// 終端機字體（必須設為 Nerd Font，oh-my-posh 圖示才能正確顯示）
"terminal.integrated.fontFamily": "MesloLGM NF"
```

> **注意：** 編輯器與終端機的字體設定是分開的。
> `terminal.integrated.fontFamily` 才是關鍵，沒設定的話 VS Code 內建終端機的 oh-my-posh 圖示會顯示為亂碼。

---

## 換主題

1. 下載新主題：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/【主題名稱】.omp.json" -OutFile "$env:LOCALAPPDATA\oh-my-posh\themes\【主題名稱】.omp.json"
```

2. 修改兩個 `$PROFILE` 裡的主題檔名。

3. 重新開啟 PowerShell 生效。

---

## 常見問題

### CONFIG NOT FOUND

`$env:POSH_THEMES_PATH` 未設定，或安裝的是 Store 版本。
解法：手動下載主題檔案（見 Step 5），並在 `$PROFILE` 使用完整路徑。

### posh-git 找不到模組

PowerShell 7 與 Windows PowerShell 5.1 的模組各自獨立，需分別安裝。

### 圖示顯示為亂碼

Windows Terminal 尚未設定 Nerd Font，請確認 `settings.json` 的 `font.face` 已設為 `MesloLGM NF`。
