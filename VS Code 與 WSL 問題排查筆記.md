# VS Code 與 WSL 問題排查筆記

## 問題描述

在 VS Code 開啟時或執行某些動作時，會彈出 CMD 視窗顯示：

```
Windows 子系統 Linux 版必須更新至最新版本才能繼續。
您可以執行 'wsl.exe --update' 來更新。
```

由於公司電腦有 GCB（Government Configuration Baseline）限制，Hyper-V 被禁用，因此無法安裝或使用 WSL。

---

## 根本原因

1. **WSL 處於部分安裝狀態**：系統中存在 `wsl.exe`（位於 `C:\Windows\System32\wsl.exe`），但 WSL 功能未完成安裝

2. **VS Code 預設行為**：VS Code 啟動時會自動掃描系統上所有可用的 terminal profiles，包括 WSL distributions。當 `terminal.integrated.useWslProfiles` 設定為 `true`（預設值）時，VS Code 會調用 `wsl.exe --list` 來查詢可用的 WSL distributions

3. **結果**：每次 VS Code 嘗試偵測 WSL 時，就會觸發安裝提示視窗

---

## 解決方案

在 VS Code 的 `settings.json` 中加入以下設定：

```json
"terminal.integrated.useWslProfiles": false
```

這會阻止 VS Code 嘗試偵測 WSL distributions，因此不會調用 `wsl.exe`。

### 設定檔位置

```
C:\Users\<使用者名稱>\AppData\Roaming\Code\User\settings.json
```

### 開啟設定檔的方式

1. 按 `Ctrl + Shift + P`
2. 輸入 `Open User Settings (JSON)`
3. 選擇它來開啟 `settings.json`

---

## 排查過程中嘗試的方法

### 1. 設定預設終端機

```json
"terminal.integrated.defaultProfile.windows": "PowerShell"
```

- 作用：指定 VS Code 使用 PowerShell 作為預設終端機
- 結果：無法解決問題，因為 VS Code 仍會在啟動時掃描所有可用的 shell

### 2. 移除可能觸發 WSL 的擴充套件

使用以下指令移除擴充套件：

```powershell
code --uninstall-extension ms-vscode-remote.remote-containers
code --uninstall-extension docker.docker
code --uninstall-extension ms-azuretools.vscode-containers
code --uninstall-extension ms-vscode-remote.remote-wsl
```

- 結果：無法解決問題，因為問題來自 VS Code 核心功能而非擴充套件

### 3. 以無擴充套件模式啟動 VS Code

```powershell
code --disable-extensions
```

- 作用：啟動 VS Code 但不載入任何擴充套件
- 用途：用來判斷問題是否來自擴充套件
- 結果：問題仍然存在，確認問題不是擴充套件造成的

---

## 學到的觀念與技術

### VS Code Terminal 相關設定

| 設定項目 | 說明 |
|---------|------|
| `terminal.integrated.defaultProfile.windows` | 指定 Windows 上的預設終端機 |
| `terminal.integrated.profiles.windows` | 定義可用的終端機 profiles |
| `terminal.integrated.useWslProfiles` | 是否自動偵測 WSL distributions（預設 `true`） |

### VS Code 擴充套件管理指令

```powershell
# 列出所有已安裝的擴充套件
code --list-extensions

# 安裝擴充套件
code --install-extension <extension-id>

# 移除擴充套件
code --uninstall-extension <extension-id>

# 停用擴充套件
code --disable-extension <extension-id>

# 以無擴充套件模式啟動
code --disable-extensions
```

### WSL (Windows Subsystem for Linux)

- WSL 是 Windows 上運行 Linux 環境的子系統
- WSL 2 需要 Hyper-V 虛擬化技術支援
- 如果 Hyper-V 被禁用（如 GCB 限制），WSL 將無法正常運作
- `wsl.exe` 位於 `C:\Windows\System32\wsl.exe`

### 檢查 WSL 狀態的指令

```powershell
# 檢查 WSL 狀態
wsl --status

# 列出已安裝的 distributions
wsl --list

# 更新 WSL
wsl --update
```

### GCB (Government Configuration Baseline)

- 政府組態基準，用於規範政府機關電腦的安全性設定
- 通常會限制許多功能，包括 Hyper-V、WSL 等虛擬化相關功能

---

## 相關的 VS Code 設定檔結構

```
C:\Users\<使用者名稱>\AppData\Roaming\Code\User\
├── settings.json          # 使用者設定
├── keybindings.json       # 快捷鍵設定
├── globalStorage\         # 擴充套件的全域儲存
└── workspaceStorage\      # 工作區儲存
```

---

## 總結

當遇到 VS Code 不斷嘗試啟動 WSL 的問題時：

1. **先確認是否真的需要 WSL**：如果不需要，直接禁用偵測
2. **設定 `terminal.integrated.useWslProfiles: false`**：這是最直接的解決方案
3. **排查問題時可以用 `code --disable-extensions`**：確認問題是否來自擴充套件
