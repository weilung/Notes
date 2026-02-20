# GitHub 多帳號 SSH Key 設定筆記

## 概述

多人共用**同一個 Windows 帳號**，各自有不同的 GitHub 帳號。如果使用 HTTPS 認證，Windows 認證管理員（Credential Manager）只能存一組認證，導致 push 時用到別人的帳號。

> **注意**：如果每個人有各自的 Windows 帳號（不同的 `C:\Users\<名稱>`），各自的 `~/.ssh/` 和認證管理員本來就是分開的，不會有帳號衝突問題。本篇針對的是**共用同一個 Windows 帳號**的情境。

本篇說明：
1. HTTPS 與 SSH Key 認證的運作差異
2. 多帳號 SSH Key 設定的完整步驟

---

## Git 認證方式比較：HTTPS vs SSH Key

### HTTPS 認證的運作方式

HTTPS 認證使用 **帳號 + Personal Access Token（PAT）** 進行身份驗證。Git 透過 Windows 認證管理員（Credential Manager）儲存認證資訊，避免每次都要輸入。

問題在於：**認證管理員只會儲存一組 GitHub 認證**，多帳號時會互相覆蓋。

```
┌─────────── 一台 PC，三個使用者 ───────────┐
│                                            │
│  使用者 A ─┐                               │
│  使用者 B ─┼─→ Windows 認證管理員          │
│  使用者 C ─┘   （只存一組 GitHub 認證！）   │
│                     │                      │
│                     ▼                      │
│              ┌─────────────┐               │
│              │ github.com  │               │
│              │ user: ???   │  ← 誰的？     │
│              │ token: ???  │               │
│              └─────────────┘               │
│                     │                      │
│                     ▼                      │
│  git push → 永遠用這組認證 → 帳號衝突！    │
└────────────────────────────────────────────┘
```

典型症狀：使用者 B 執行 `git push`，但 GitHub 回報權限錯誤，因為認證管理員裡存的是使用者 A 的 token。

### SSH Key 認證的運作方式

SSH Key 使用**公鑰/私鑰**機制：

- **私鑰**（Private Key）：留在自己電腦，像**鑰匙**
- **公鑰**（Public Key）：放到 GitHub 帳號，像**鎖**

> **比喻**：每個人有自己的鑰匙（私鑰），並在 GitHub 帳號上裝了對應的鎖（公鑰）。連線時，GitHub 用鎖驗證鑰匙是否匹配，匹配就放行。

每個帳號各一組 Key，透過 SSH config 指定誰用哪把鑰匙，**互不干擾**。

```
┌─────────── 一台 PC，三個使用者 ───────────┐
│                                            │
│  使用者 A → 私鑰 A ──→ GitHub 帳號 A      │
│                          （公鑰 A）        │
│                                            │
│  使用者 B → 私鑰 B ──→ GitHub 帳號 B      │
│                          （公鑰 B）        │
│                                            │
│  使用者 C → 私鑰 C ──→ GitHub 帳號 C      │
│                          （公鑰 C）        │
│                                            │
│  SSH config 指定每個帳號用哪把私鑰         │
│  → 各走各的，不衝突！                      │
└────────────────────────────────────────────┘
```

### 比較表

| 項目 | HTTPS + 認證管理員 | SSH Key |
|------|-------------------|---------|
| 認證方式 | 帳號 + Personal Access Token | 公鑰 / 私鑰 |
| 多帳號支援 | 只能存一組，會衝突 | 每帳號各一組 Key，不衝突 |
| 切換帳號 | 手動到認證管理員刪除/替換 | 透過 SSH config 自動切換 |
| 安全性 | Token 明文存在認證管理員 | 私鑰存本機，不傳輸 |
| 初始設定 | 簡單（clone 時輸入帳密） | 需產生 Key 並設定 config |
| 適合情境 | 單帳號使用 | **多帳號共用一台電腦** |

---

## 設定步驟

以下假設有三個 GitHub 帳號：`user-a`、`user-b`、`user-c`。

### 1. 產生 SSH Key（每個帳號各一組）

為每個帳號產生獨立的 SSH Key：

```bash
# 使用者 A
ssh-keygen -t ed25519 -C "user-a@example.com" -f ~/.ssh/id_ed25519_user_a

# 使用者 B
ssh-keygen -t ed25519 -C "user-b@example.com" -f ~/.ssh/id_ed25519_user_b

# 使用者 C
ssh-keygen -t ed25519 -C "user-c@example.com" -f ~/.ssh/id_ed25519_user_c
```

**參數說明：**

| 參數 | 說明 |
|------|------|
| `-t ed25519` | 指定加密演算法。`ed25519` 是目前推薦的演算法，比舊式的 `rsa` 更安全且金鑰更短 |
| `-C "..."` | 為 Key 加上標籤（comment），通常填 email 方便辨識，不影響 Key 本身的功能 |
| `-f ~/.ssh/id_ed25519_user_a` | 指定輸出檔名。**不指定時預設為 `~/.ssh/id_ed25519`**，多帳號時必須指定不同檔名，否則後產生的 Key 會覆蓋前一個 |

> **單帳號情境**：如果只有一個 GitHub 帳號，可以不加 `-f`，直接用預設的 `~/.ssh/id_ed25519`，SSH 連線時會自動找到這個檔案，也不需要額外設定 `~/.ssh/config`。

> **檔名命名規則**：預設檔名 `id_ed25519` 由兩部分組成——`id`（identity 縮寫，SSH Key 的慣例前綴）加上演算法名稱（`ed25519`）。多帳號時在後面加上使用者名稱以區分，例如 `id_ed25519_user_a`。

產生後會有兩個檔案：

```
~/.ssh/id_ed25519_user_a       ← 私鑰（不要外傳）
~/.ssh/id_ed25519_user_a.pub   ← 公鑰（要貼到 GitHub）
```

passphrase 可設可不設，設了更安全但每次使用需輸入（可用 ssh-agent 避免重複輸入，見常見問題）。

### 2. 將公鑰加到 GitHub 帳號

每個使用者登入自己的 GitHub 帳號，新增對應的公鑰：

1. 複製公鑰內容：
   ```bash
   # 顯示公鑰內容，複製整段輸出
   cat ~/.ssh/id_ed25519_user_a.pub
   ```

2. 到 GitHub → **Settings** → **SSH and GPG keys** → **New SSH key**

3. 貼上公鑰內容，Title 取個好辨識的名稱（如 `shared-pc-user-a`）

每個帳號各自加入自己的公鑰。

### 3. 設定 SSH config（區分不同帳號）

編輯 `~/.ssh/config`（不存在就建立）：

```
# 使用者 A 的 GitHub
Host github-user-a
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_user_a
    IdentitiesOnly yes

# 使用者 B 的 GitHub
Host github-user-b
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_user_b
    IdentitiesOnly yes

# 使用者 C 的 GitHub
Host github-user-c
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_user_c
    IdentitiesOnly yes
```

> **重點**：`Host` 是自定義的別名，實際連線目標由 `HostName` 決定。`IdentitiesOnly yes` 確保只用指定的 Key，不會嘗試其他 Key。

### 4. 設定 Git repo 使用對應的 remote

clone 或設定 remote 時，把 `github.com` 替換成 SSH config 中的 `Host` 別名：

```bash
# 原本的 SSH URL
git@github.com:user-a/my-repo.git

# 改成使用別名
git@github-user-a:user-a/my-repo.git
#      ↑ 對應 SSH config 的 Host
```

**clone 時直接用別名：**

```bash
# 使用者 A clone 自己的 repo
git clone git@github-user-a:user-a/my-repo.git

# 使用者 B clone 自己的 repo
git clone git@github-user-b:user-b/my-repo.git
```

**也別忘了設定 repo 的使用者資訊**（避免 commit 記錄混淆）：

```bash
# 在 repo 目錄下設定（不加 --global，只影響這個 repo）
git config user.name "User A"
git config user.email "user-a@example.com"
```

### 5. 測試連線

```bash
# 測試使用者 A 的連線
ssh -T github-user-a
# 預期輸出：Hi user-a! You've successfully authenticated, but GitHub does not provide shell access.

# 測試使用者 B
ssh -T github-user-b

# 測試使用者 C
ssh -T github-user-c
```

如果看到 `Hi <帳號名>!` 就代表設定成功。

> **首次連線提示**：第一次連線到 GitHub 時，可能會出現以下提示：
> ```
> The authenticity of host 'github.com (...)' can't be established.
> Are you sure you want to continue connecting (yes/no)?
> ```
> 這是 SSH 在確認伺服器身份，輸入 `yes` 並按 Enter 即可。確認後會將 GitHub 的 fingerprint 記錄到 `~/.ssh/known_hosts`，之後不會再詢問。

### 6. 現有 repo 從 HTTPS 轉換為 SSH

**先確認目前使用的認證方式：**

```bash
git remote -v
```

從輸出的 URL 格式可以判斷：

```
# HTTPS 認證（URL 以 https:// 開頭）
origin  https://github.com/user-a/my-repo.git (fetch)

# SSH 認證（URL 以 git@ 開頭）
origin  git@github.com:user-a/my-repo.git (fetch)
origin  git@github-user-a:user-a/my-repo.git (fetch)  ← 使用別名
```

**若為 HTTPS，改為 SSH：**

```bash
# 改為 SSH（使用對應的別名）
git remote set-url origin git@github-user-a:user-a/my-repo.git

# 確認已更改
git remote -v
# 輸出範例：origin  git@github-user-a:user-a/my-repo.git (fetch)
```

---

## 新帳號加入流程

當有新的使用者要加入這台 PC，按以下步驟操作：

1. **產生 Key**：
   ```bash
   ssh-keygen -t ed25519 -C "new-user@example.com" -f ~/.ssh/id_ed25519_new_user
   ```

2. **公鑰加到 GitHub**：登入 GitHub → Settings → SSH and GPG keys → 貼上 `.pub` 內容

3. **更新 SSH config**：在 `~/.ssh/config` 加入新的 Host 區塊：
   ```
   Host github-new-user
       HostName github.com
       User git
       IdentityFile ~/.ssh/id_ed25519_new_user
       IdentitiesOnly yes
   ```

4. **測試**：
   ```bash
   ssh -T github-new-user
   ```

5. **clone 或設定 remote** 時使用 `github-new-user` 別名

---

## 常見問題

### Q: `Permission denied (publickey)` 怎麼辦？

檢查項目：
1. 公鑰是否已加到 GitHub 帳號
2. SSH config 的 `IdentityFile` 路徑是否正確
3. 私鑰檔案權限是否正確（Linux/Mac 需要 `chmod 600`）
4. 用 `ssh -vT github-user-a` 查看詳細連線過程，確認使用了正確的 Key

### Q: 每次都要輸入 passphrase，很麻煩？

使用 ssh-agent 記住 passphrase：

```bash
# 啟動 ssh-agent
eval "$(ssh-agent -s)"

# 加入私鑰（只需輸入一次 passphrase）
ssh-add ~/.ssh/id_ed25519_user_a
```

Windows 可以啟用 OpenSSH Authentication Agent 服務，讓它開機自動執行：

```powershell
# 以管理員身分執行
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

### Q: 可以不設定 SSH config，用預設的 Key 嗎？

單帳號可以，但多帳號**一定要設定 SSH config**。因為 `github.com` 只有一個，SSH 無法自動判斷該用哪把 Key，必須透過不同的 Host 別名來區分。

### Q: 如何查詢電腦上是否已有 HTTPS 認證？

```bash
cmdkey /list
```

輸出中若出現 `git:https://github.com`，代表有存 GitHub 的 HTTPS 認證。也可以到 **控制台** → **認證管理員** → **Windows 認證** 分頁查看。

### Q: 已經在認證管理員裡存了 HTTPS 認證，需要刪除嗎？

改用 SSH 後，HTTPS 認證不會影響 SSH 連線。但建議清除以避免混淆：

**方法一：指令（快）**
```bash
cmdkey /delete:git:https://github.com
```

**方法二：介面**
1. 開啟 **控制台** → **認證管理員**（Credential Manager）
2. 找到 `git:https://github.com`
3. 點擊 **移除**

清除後可再執行 `cmdkey /list` 確認已移除。
