# Git 移除誤入版控的建置產物教學

## 問題情境

專案開發時忘了建立 `.gitignore`，導致建置產物（如 .NET 的 `bin/`、`obj/`，Node.js 的 `node_modules/`、`dist/`）被 commit 進版控。

這些檔案會造成：

- Repository 體積暴增（`node_modules` 輕易上千個檔案）
- 每次 build 都會產生無意義的 diff
- 協作者 clone 時浪費頻寬和時間

單純在之後加 `.gitignore` 並刪除檔案，**只能讓新 commit 不再追蹤**，但歷史中仍然保留這些檔案。要徹底移除，必須**重寫 Git 歷史**。

---

## 核心概念

### Git commit 是快照，不是差異

Git 的每個 commit 儲存的是整個專案的完整快照（snapshot），不是與上一版的差異（diff）。因此，一旦檔案被 commit，即使後來刪除，它依然存在於歷史中。

### `git reset` 的三種模式

| 模式 | HEAD | Staging Area | 工作目錄 | 用途 |
|------|------|-------------|---------|------|
| `--soft` | 移動 | **保留** | **保留** | 只退回 commit，檔案仍在 staged |
| `--mixed`（預設） | 移動 | **清除** | **保留** | 退回 commit，檔案變成 unstaged |
| `--hard` | 移動 | **清除** | **清除** | 完全回到指定 commit，**工作目錄的修改會遺失** |

### `git show <commit>:<path>` — 取得歷史版本的檔案內容

從指定的歷史 commit 中取出**該時間點的檔案內容**，輸出到 stdout。可以搭配重導向寫入檔案：

```bash
git show abc1234:path/to/file > path/to/file
```

也可以用 `-C` 參數從其他 repo 取檔案（例如從備份目錄）：

```bash
git -C /path/to/backup show abc1234:path/to/file > path/to/file
```

> **注意**：`git checkout <commit> -- <path>` 也能取出歷史版本，但它會**同時覆蓋工作目錄和 staging area**。如果工作目錄有未 commit 的修改，會被靜默覆蓋。

---

## 常見陷阱

在實作前，先了解兩個容易犯的錯誤，避免重做：

### 陷阱 1：工作目錄的檔案是最終版本，不是各 commit 當時的版本

`git reset` 之後，工作目錄中的檔案停留在**最後一個 commit 的狀態**。如果直接用 `git add` 加入這些檔案來重建早期的 commit，早期 commit 會包含後來才有的修改。

**錯誤做法**：

```bash
git reset --soft <base-commit>
git reset HEAD
git add backend/Service.cs    # 這是最終版本，不是早期 commit 的版本！
git commit -m "early commit"
```

**正確做法**：每個 commit 的每個檔案，都必須用 `git show` 取得**該 commit 當時的版本**：

```bash
git show <原始commit>:backend/Service.cs > backend/Service.cs
git add backend/Service.cs
git commit -m "early commit"
```

### 陷阱 2：未 commit 的修改會被覆蓋

重寫歷史的過程中，`git checkout <commit> -- <path>` 和 `git show ... > file` 都會覆蓋工作目錄中的檔案。如果你有**進行中但未 commit 的修改**，這些修改會靜悄悄地消失。

**解法**：在開始重寫之前，先用 `git stash` 保護未 commit 的修改：

```bash
git stash --include-untracked   # 保存所有未 commit 的修改（含 untracked 檔案）
# ... 完成重寫和驗證 ...
git stash pop                   # 還原修改
```

---

## 實作步驟

以下以實際案例說明：一個有 6 個 commit 的專案，其中 `bin/`、`obj/`、`node_modules/` 從第 2 個 commit 開始被誤加入。

### Step 1：調查問題範圍

找出建置產物最早在哪個 commit 被加入：

```bash
# --diff-filter=A 只列出「新增（Added）」的檔案
git log --oneline --diff-filter=A -- "backend/bin/*" "backend/obj/*"
git log --oneline --diff-filter=A -- "frontend/node_modules/*" "frontend/dist/*"
```

查看特定 commit 中有多少建置產物：

```bash
git show --stat <commit-hash> | grep -cE "(bin/|obj/|node_modules/|dist/)"
```

### Step 2：記錄每個 commit 的資訊

在動手之前，**務必先記錄**所有需要重建的 commit 資訊：

```bash
# 列出每個 commit 的乾淨檔案（排除建置產物）
git show --name-only <commit> | grep -vE "^(backend/bin/|backend/obj/|frontend/node_modules/|frontend/dist/)"

# 取得 commit 訊息、作者、日期
git log -1 --format="AUTHOR:%an <%ae>%nDATE:%aI%nMSG:%B" <commit>
```

> **重要**：這步不可省略。Reset 之後如果忘了原始 commit 內容，就很難還原。

### Step 3：建立備份 tag

```bash
git tag backup-before-rewrite HEAD
```

這個 tag 有兩個用途：

1. **復原用** — 萬一操作失敗，可以 `git reset --hard backup-before-rewrite` 回到原始狀態
2. **重建時的檔案來源** — 即使 reset 之後，原始 commit 歷史仍然可以透過 hash 存取，用 `git show <原始commit>:<path>` 取得正確版本的檔案

> **額外保險**：如果擔心操作過程中誤刪 tag 或 reflog 過期，可以再複製一份整個目錄作為備份：`cp -r my-project my-project-backup`。但這不是必要步驟。

### Step 4：保護未 commit 的修改

```bash
git stash --include-untracked
```

確認 `git status` 顯示乾淨的工作目錄後再繼續。

### Step 5：Reset 到乾淨的起點

假設問題從 `abc1234`（第 2 個 commit）開始，而 `def5678`（第 1 個 commit）是乾淨的：

```bash
# 先 soft reset：HEAD 回到乾淨 commit，但所有檔案保留在 staged
git reset --soft def5678

# 再 unstage 所有檔案，讓我們可以手動控制每個 commit 要加入哪些檔案
git reset HEAD
```

此時所有檔案都還在工作目錄中，但不屬於任何 commit。

### Step 6：建立 `.gitignore`

在重建 commit 之前先建立 `.gitignore`，後續 `git add` 會自動忽略這些路徑：

```gitignore
# .NET
bin/
obj/
*.user
*.suo

# Node
node_modules/
dist/

# IDE
.vs/
.vscode/

# OS
Thumbs.db
.DS_Store

# Environment
.env
.env.*
!.env.example
```

### Step 7：按原始順序重建每個 commit

對每個原始 commit，需要將該 commit 當時的檔案版本寫入工作目錄，然後重新 commit。這裡有兩個選擇點：

#### 選擇 1：檔案來源 — 從當前 repo 或備份目錄取檔

**選項 A — 從當前 repo 取檔**（backup tag 還在時）：

```bash
git show <原始commit>:path/to/file
```

reset 後原始 commit hash 仍然有效（backup tag 指向的歷史還在），可以直接存取。

**選項 B — 從備份目錄取檔**（額外保險）：

```bash
git -C /path/to/backup show <原始commit>:path/to/file
```

`-C` 讓 git 到備份目錄的 repo 中查找 commit 歷史。注意 `-C` 只影響 git 去哪裡找歷史，**不影響 `>` 重導向的輸出位置**——`>` 是 shell 層級的操作，永遠以你執行命令時所在的目錄為基準：

```bash
# 假設你在 E:/VsProject/MyProject 下執行
git -C "E:/VsProject/MyProject-backup" show abc123:src/App.tsx > src/App.tsx
#       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                       ^^^^^^^^^^^
#       git 去備份目錄找 commit 歷史                              寫入 E:/VsProject/MyProject/src/App.tsx
```

適合以下情況：backup tag 已刪除、reflog 已過期、或想確保不依賴當前 repo 的狀態。

#### 選擇 2：取檔方式 — 逐檔還原或批次還原

**選項 A — `git show` 逐檔還原**：

```bash
# 取得該 commit 中某個檔案的完整內容，寫入工作目錄
git show <原始commit>:path/to/file > path/to/file

# 手動加入 staging
git add path/to/file
```

- 只覆寫工作目錄，**不會自動 stage**
- 適合需要精確控制哪些檔案進 staging 的情況

**選項 B — `git checkout` + `git diff-tree` 批次還原**：

```bash
# 從該 commit 的變更檔案清單中，排除建置產物，一次全部還原
git diff-tree --no-commit-id --name-only -r <原始commit> \
  | grep -vE "^(backend/bin/|backend/obj/|frontend/node_modules/|frontend/dist/)" \
  | xargs git checkout <原始commit> --
```

- 同時寫入**工作目錄 + staging area**，省去手動 `git add` 的步驟
- `git diff-tree` 列出該 commit 變更的所有檔案，搭配 `grep -v` 過濾建置產物
- 也可以直接指定目錄路徑：`git checkout <原始commit> -- backend/ frontend/src/`

#### 兩個選擇點的比較

**檔案來源**：

| | 從當前 repo | 從備份目錄 |
|--|------------|-----------|
| 前提 | backup tag 或 reflog 還在 | 有事先複製的目錄備份 |
| 指令 | `git show <commit>:<path>` | `git -C /backup show <commit>:<path>` |
| 適用時機 | 大多數情況 | tag 已刪或想要額外保險 |

**取檔方式**：

| | `git show ... > file` | `git checkout` + `git diff-tree` |
|--|----------------------|----------------------------------|
| 覆寫工作目錄 | 是 | 是 |
| 自動 stage | 否 | **是** |
| 適用場景 | 需要精確控制 staging | 批次處理，效率高 |

#### 完成 commit

取得檔案後，處理刪除操作（如果有），然後 commit：

```bash
# 如果該 commit 包含刪除操作
git rm -r path/to/deleted-dir/

# 建立 commit，保留原始日期和訊息
git commit --date="2026-04-08T15:13:44+08:00" -m "原始 commit 訊息"
```

**關鍵提醒**：

- `.gitignore` 放在第一個重建的 commit 中，這樣後續 commit 都受到保護
- 使用 `--date` 保留原始的 commit 時間
- **每個檔案都必須從原始 commit 取得該時間點的版本**，不可直接用工作目錄中的檔案（因為那是最終版本）

### Step 8：驗證結果

驗證分兩個層次：

**層次 1 — 確認建置產物已移除**：

```bash
# 確認所有新 commit 都不包含建置產物
for commit in $(git log --oneline --format="%h" def5678..HEAD); do
  count=$(git show --stat $commit | grep -cE "(bin/|obj/|node_modules/|dist/)")
  echo "$commit: $count build artifacts"
done
```

每個 commit 的 build artifacts 數量都應為 0。

**層次 2 — 逐 commit 逐檔比對內容**（確保沒有檔案版本錯置）：

使用 backup tag 所保留的原始 commit hash 進行比對。如果有目錄備份，可將 `git show` 改為 `git -C /path/to/backup show`。

```bash
# 定義新舊 commit 的對應關係
NEW_COMMITS=(new1 new2 new3 new4 new5 new6)
OLD_COMMITS=(old1 old2 old3 old4 old5 old6)

errors=0
for i in 0 1 2 3 4 5; do
  new=${NEW_COMMITS[$i]}
  old=${OLD_COMMITS[$i]}

  # 取得該 commit 中所有檔案
  files=$(git show --name-only --format="" $new | grep -v '^$')

  while IFS= read -r f; do
    new_hash=$(git show "$new:$f" | md5sum | cut -d' ' -f1)
    old_hash=$(git show "$old:$f" 2>/dev/null | md5sum | cut -d' ' -f1)

    if [ "$new_hash" != "$old_hash" ]; then
      echo "MISMATCH commit $i ($new vs $old): $f"
      errors=$((errors+1))
    fi
  done <<< "$files"
done

echo "=== Total mismatches: $errors ==="
```

預期結果：除了新增的 `.gitignore`（原始 commit 中不存在）以外，所有檔案的 hash 都應一致。

### Step 9：還原未 commit 的修改並清理

```bash
# 還原進行中的工作
git stash pop

# 確認 git status 與重寫前一致
git status

# 一切正確後，刪除備份 tag
git tag -d backup-before-rewrite
```

---

## 大量 commit 的替代方案：`git filter-repo`

如果受影響的 commit 有幾十個以上，手動重建不切實際。推薦使用 `git filter-repo`（需另外安裝）：

```bash
# 安裝
pip install git-filter-repo

# 從所有歷史中移除指定路徑
git filter-repo --path backend/bin --path backend/obj --path frontend/node_modules --path frontend/dist --invert-paths
```

`--invert-paths` 表示「保留所有路徑，**除了**指定的這些」。這會自動遍歷所有 commit 並移除這些目錄。此方式不會有檔案版本錯置的問題，因為它是自動化處理每個 commit 的 tree。

---

## 注意事項

### 重寫歷史會改變所有 commit hash

因為 Git 的 commit hash 是根據內容 + parent commit 計算的，一旦修改了某個 commit，它之後的所有 commit hash 都會改變。

### 已推送到 remote 的情況

如果被重寫的 commits 已經推送到 remote：

1. 需要使用 `git push --force` 強制推送
2. **所有協作者**必須重新處理他們的本地分支：
   ```bash
   # 協作者執行（最簡單的方式）
   git fetch origin
   git reset --hard origin/<branch-name>
   ```
3. 建議在團隊溝通後再執行，避免其他人的工作遺失

### 最佳實踐：從一開始就加 `.gitignore`

預防勝於治療。建立新專案時，第一個 commit 就應該包含 `.gitignore`。

常用模板可參考：[github/gitignore](https://github.com/github/gitignore)

- .NET：`VisualStudio.gitignore`
- Node.js：`Node.gitignore`
