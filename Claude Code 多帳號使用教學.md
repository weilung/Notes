# Claude Code 多帳號使用教學

在同一台電腦上同時使用多個 Claude Code 帳號的方法。

## 原理說明

Claude Code 使用 `CLAUDE_CONFIG_DIR` 環境變數來決定設定檔的存放位置。

- **未設定時**：使用預設目錄 `~/.claude`
- **有設定時**：使用指定的目錄

透過為不同帳號指定不同的設定目錄，就可以同時運行多個帳號。

## 設定步驟

---

### Windows

#### 步驟 1：建立啟動腳本

在 Claude Code 的安裝目錄（通常是 `C:\Users\<使用者名稱>\.local\bin`）建立 `.cmd` 檔案。

**範例：account1.cmd**
```batch
@echo off
set CLAUDE_CONFIG_DIR=C:\Users\<使用者名稱>\.claude-account1
echo [Account 1]
claude %*
```

**範例：account2.cmd**
```batch
@echo off
set CLAUDE_CONFIG_DIR=C:\Users\<使用者名稱>\.claude-account2
echo [Account 2]
claude %*
```

> 請將 `<使用者名稱>` 替換為你的 Windows 使用者名稱。

#### 步驟 2：首次登入

在終端（PowerShell 或 CMD）中執行腳本：

```powershell
account1
```

#### 步驟 3：日常使用

```powershell
account1    # 啟動第一個帳號
account2    # 啟動第二個帳號
```

---

### macOS / Linux / WSL

這三個平台作法相同，都使用 Shell 腳本。

#### 步驟 1：建立啟動腳本

在 `~/.local/bin` 或其他在 `$PATH` 中的目錄建立腳本。

**範例：account1**
```bash
#!/bin/bash
export CLAUDE_CONFIG_DIR="$HOME/.claude-account1"
echo "[Account 1]"
claude "$@"
```

**範例：account2**
```bash
#!/bin/bash
export CLAUDE_CONFIG_DIR="$HOME/.claude-account2"
echo "[Account 2]"
claude "$@"
```

#### 步驟 2：設定執行權限

```bash
chmod +x ~/.local/bin/account1
chmod +x ~/.local/bin/account2
```

#### 步驟 3：首次登入

在終端中執行腳本：

```bash
account1
```

第一次執行時會提示登入，使用對應的帳號完成登入。

#### 步驟 4：日常使用

```bash
account1    # 啟動第一個帳號
account2    # 啟動第二個帳號
```

---

## 首次登入流程

無論哪個平台，第一次執行時：
1. 系統會自動建立新的設定目錄
2. 提示你登入 Claude 帳號
3. 使用對應的帳號完成登入

對每個腳本重複此步驟，分別登入不同的帳號。

## 重要觀念

### 環境變數的運作方式

- 環境變數在**程式啟動時**被讀取並固定
- 啟動後修改環境變數**不會影響**已運行的實例
- 每個終端窗口的環境變數是獨立的

### 確認目前使用的帳號

在 Claude Code 中輸入 `/status` 可以查看目前登入的帳號資訊。

### 設定檔存放位置

| 帳號 | 設定目錄 |
|------|----------|
| 預設（直接執行 `claude`） | `~/.claude` |
| account1 | `~/.claude-account1` |
| account2 | `~/.claude-account2` |

每個目錄包含：
- 登入認證資訊
- 對話歷史記錄
- 個人設定

## 注意事項

1. **首次使用**：每個新的設定目錄都需要重新登入
2. **獨立存放**：各帳號的對話記錄和設定完全獨立
3. **同時運行**：建議每個帳號使用獨立的終端窗口，避免混淆

## 進階：加入 Shell Profile

將函數加入 Shell Profile 可以更方便使用。

---

### Windows PowerShell

編輯 Profile：
```powershell
notepad $PROFILE
```

加入以下內容：
```powershell
function account1 {
    $env:CLAUDE_CONFIG_DIR = "C:\Users\<使用者名稱>\.claude-account1"
    Write-Host "[Account 1]" -ForegroundColor Cyan
    claude $args
}

function account2 {
    $env:CLAUDE_CONFIG_DIR = "C:\Users\<使用者名稱>\.claude-account2"
    Write-Host "[Account 2]" -ForegroundColor Green
    claude $args
}
```

儲存後重新開啟 PowerShell 即可使用。

---

### macOS / Linux / WSL（Bash / Zsh）

編輯 `~/.bashrc`（Bash）或 `~/.zshrc`（Zsh）：

```bash
# Claude Code 多帳號
account1() {
    export CLAUDE_CONFIG_DIR="$HOME/.claude-account1"
    echo "[Account 1]"
    claude "$@"
}

account2() {
    export CLAUDE_CONFIG_DIR="$HOME/.claude-account2"
    echo "[Account 2]"
    claude "$@"
}
```

儲存後執行 `source ~/.bashrc` 或重新開啟終端即可使用。

---

## 快速對照表

| 項目 | Windows | macOS / Linux / WSL |
|------|---------|---------------------|
| 腳本格式 | `.cmd` 或 `.bat` | 無副檔名（Shell 腳本） |
| 設定環境變數 | `set VAR=value` | `export VAR="value"` |
| 傳遞參數 | `%*` | `"$@"` |
| 設定執行權限 | 不需要 | `chmod +x` |
| Profile 位置 | `$PROFILE` | `~/.bashrc` 或 `~/.zshrc` |
| 預設設定目錄 | `C:\Users\<使用者>\.claude` | `~/.claude` |

## 參考資料

- Claude Code 官方文件：https://docs.anthropic.com/claude-code
- `CLAUDE_CONFIG_DIR` 環境變數用於自訂設定檔存放位置
