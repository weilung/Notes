# VS Code 系列編輯器擴展管理指南

本指南說明如何批量管理 VS Code、Cursor、Antigravity 的擴展，包含移除、安裝及常見問題排除。

## 目錄

- [編輯器與 Marketplace 對照表](#編輯器與-marketplace-對照表)
- [擴展清單檔案說明](#擴展清單檔案說明)
- [移除所有擴展](#移除所有擴展)
- [批量安裝擴展](#批量安裝擴展)
- [常見問題排除](#常見問題排除)
- [附錄：擴展清單範本](#附錄擴展清單範本)

---

## 編輯器與 Marketplace 對照表

| 編輯器 | CLI 指令 | Marketplace | 備註 |
|--------|----------|-------------|------|
| VS Code | `code` | VS Code Marketplace | 支援所有擴展 |
| Cursor | `cursor` | Open VSX | 內建 AI，不需要 Copilot |
| Antigravity | `antigravity` | Open VSX | 內建 AI |

### VS Code Marketplace 授權限制

Microsoft Visual Studio Marketplace 使用條款規定，只有以下產品可以使用：
- Visual Studio
- VS Code (官方)
- GitHub Codespaces
- Azure DevOps

**Cursor、Antigravity 等第三方編輯器無法使用 VS Code Marketplace**，即使修改 settings.json 切換來源，也會在 API 層面被阻擋。

### Marketplace 擴展差異與替代方案

| 擴展 | VS Code Marketplace | Open VSX | 替代方案 |
|------|:-------------------:|:--------:|----------|
| ms-dotnettools.csharp | ✓ | ✗ | muhammad-sammy.csharp |
| ms-dotnettools.csdevkit | ✓ | ✗ | (無) |
| ms-python.vscode-pylance | ✓ | ✗ | Cursor 自動安裝 cursorpyright |
| github.copilot | ✓ | ✗ | Cursor/Antigravity 內建 AI |

---

## 擴展清單檔案說明

建立以下兩個檔案，放在使用者目錄 (`~` 或 `%USERPROFILE%`)：

| 檔案 | 用途 |
|------|------|
| `extensions-vscode.txt` | 完整清單，給 **VS Code** |
| `extensions-openvsx.txt` | Open VSX 可用，給 **Cursor / Antigravity** |

---

## 移除所有擴展

### VS Code

```powershell
code --list-extensions | ForEach-Object { code --uninstall-extension $_ }
```

### Cursor

```powershell
cursor --list-extensions | ForEach-Object { cursor --uninstall-extension $_ }
```

### Antigravity

```powershell
antigravity --list-extensions | ForEach-Object { antigravity --uninstall-extension $_ }
```

### 確認已全部移除

```powershell
code --list-extensions      # 應該無輸出
cursor --list-extensions    # 應該無輸出
antigravity --list-extensions
```

---

## 批量安裝擴展

### VS Code

```powershell
Get-Content ~/extensions-vscode.txt | Where-Object { $_ -and $_ -notmatch '^#' } | ForEach-Object { code --install-extension $_ }
```

### Cursor

```powershell
Get-Content ~/extensions-openvsx.txt | Where-Object { $_ -and $_ -notmatch '^#' } | ForEach-Object { cursor --install-extension $_ }
```

### Antigravity

```powershell
Get-Content ~/extensions-openvsx.txt | Where-Object { $_ -and $_ -notmatch '^#' } | ForEach-Object { antigravity --install-extension $_ }
```

---

## 常見問題排除

### 1. 批量安裝時全部顯示 "Extension not found"

**原因：** 檔案使用 Windows 換行符號 (CRLF)，在某些環境下讀取會有問題。

**解決方案：**

方法一：使用 Git Bash 或 WSL 修正換行符號
```bash
sed -i 's/\r$//' ~/extensions-vscode.txt
```

方法二：確保檔案儲存為 UTF-8 (LF) 格式

方法三：單獨測試安裝確認 CLI 正常
```powershell
code --install-extension eamodio.gitlens
```

### 2. Cursor/Antigravity 無法安裝 ms-dotnettools.csharp

**原因：** Microsoft 官方 C# 擴展未上架 Open VSX，且 VS Code Marketplace 會阻擋第三方編輯器。

**解決方案：** 使用開源替代版本
```powershell
cursor --install-extension muhammad-sammy.csharp
antigravity --install-extension muhammad-sammy.csharp
```

### 3. Cursor/Antigravity 無法安裝 GitHub Copilot

**原因：** Copilot 未上架 Open VSX，且 Cursor/Antigravity 內建 AI 功能。

**解決方案：** 不需要安裝，直接使用內建的 AI 功能。

### 4. 想切換 Antigravity 到 VS Code Marketplace

**結論：無效。** 即使在 settings.json 加入以下設定：

```json
{
  "extensions.gallery.serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
  "extensions.gallery.itemUrl": "https://marketplace.visualstudio.com/items"
}
```

VS Code Marketplace API 會檢測客戶端身份，阻擋非官方 VS Code 的請求，顯示 `Extension not found` 錯誤。

### 5. 移除擴展後 list-extensions 仍顯示擴展

**原因：** 部分擴展是其他擴展的依賴，會在依賴的擴展移除後才能移除。

**解決方案：** 重新執行移除指令，或重啟編輯器後再執行。

---

## 附錄：擴展清單範本

### extensions-vscode.txt

```
# .NET / C#
ms-dotnettools.csharp
ms-dotnettools.csdevkit
ms-dotnettools.vscode-dotnet-runtime
k--kato.docomment
kreativ-software.csharpextensions

# Python
ms-python.python
ms-python.debugpy
ms-python.vscode-pylance

# JavaScript / TypeScript
dbaeumer.vscode-eslint
esbenp.prettier-vscode
christian-kohler.path-intellisense
pranaygp.vscode-css-peek

# Git
eamodio.gitlens
mhutchie.git-graph
waderyan.gitblame
donjayamanne.githistory
codezombiech.gitignore

# AI
anthropic.claude-code
github.copilot
github.copilot-chat

# Utilities
ms-ceintl.vscode-language-pack-zh-hant
editorconfig.editorconfig
gruntfuggly.todo-tree
humao.rest-client
dotjoshjohnson.xml
mechatroner.rainbow-csv
ms-vscode.hexeditor
```

### extensions-openvsx.txt

```
# C# / .NET (開源版)
muhammad-sammy.csharp
ms-dotnettools.vscode-dotnet-runtime
k--kato.docomment

# Python
ms-python.python
ms-python.debugpy

# JavaScript / TypeScript
dbaeumer.vscode-eslint
esbenp.prettier-vscode
christian-kohler.path-intellisense
pranaygp.vscode-css-peek

# Git
eamodio.gitlens
mhutchie.git-graph
waderyan.gitblame
donjayamanne.githistory
codezombiech.gitignore

# AI
anthropic.claude-code

# Utilities
ms-ceintl.vscode-language-pack-zh-hant
editorconfig.editorconfig
gruntfuggly.todo-tree
humao.rest-client
dotjoshjohnson.xml
mechatroner.rainbow-csv
ms-vscode.hexeditor
```

---

## 備份現有擴展

日後可用以下指令備份目前安裝的擴展：

```powershell
# VS Code
code --list-extensions > ~/extensions-vscode.txt

# Cursor
cursor --list-extensions > ~/extensions-openvsx.txt

# Antigravity
antigravity --list-extensions > ~/extensions-antigravity.txt
```

---

*最後更新：2026-02-05*
