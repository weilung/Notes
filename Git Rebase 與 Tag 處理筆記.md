# Git Rebase 與 Tag 處理筆記

## Tag 在 Rebase 後會發生什麼事？

Tag 是指向**特定 commit hash** 的指標。當執行 `git rebase` 時，commit 會被重新創建並產生**新的 hash**，但 tag 仍然指向舊的 commit。

```
# Rebase 前
A---B---C  (tag: v1.0 指向 C)
     \
      D---E  (feature)

# Rebase 後
A---B---C  (tag: v1.0 還在這裡)
         \
          D'---E'  (feature，新的 commit hash)
```

結果：
- Tag 仍然存在於 repo 中
- 但在 rebase 後的分支 `git log` 中看不到該 tag
- 舊的 commit 如果沒有其他 ref 指向，最終會被 `git gc` 清除

---

## 如何保留 Tag？

### 方法 1：Rebase 前先記錄對應關係

```bash
# Rebase 前，記錄每個 tag 對應的 commit message
git log --oneline <tag-name> -1
# 輸出範例：be42d77 變更版號.

# 執行 rebase
git rebase develop

# Rebase 後，用 commit message 找新 commit
git log --oneline --grep="變更版號" <branch-name>
# 輸出範例：3a5c8f2 變更版號.
```

### 方法 2：重新建立 Tag 指向新 Commit

```bash
# 刪除舊 tag
git tag -d <tag-name>

# 重新建立 tag 指向新 commit
git tag <tag-name> <新的commit-hash>

# 如果要同步到遠端（刪除遠端舊 tag，以下兩種寫法皆可）
git push origin --delete <tag-name>         # 較直觀的寫法（Git 1.7.0+）
git push origin :refs/tags/<tag-name>       # 底層 refspec 語法

# 推送新 tag
git push origin <tag-name>
```

### 方法 3：使用 --update-refs 參數（Git 2.38+）

```bash
git rebase --update-refs develop
```

這會自動更新指向被 rebase commit 的 ref，但對 tag 的支援有限，主要用於 branch ref。

---

## 實用指令

### 查看 tag 指向的 commit

```bash
git log --oneline <tag-name> -1
```

### 查看所有 tag

```bash
git tag -l
```

### 查看 tag 與 commit 的對應

```bash
git show-ref --tags
```

### 找出兩個分支的共同祖先（查詢用，不會修改任何東西）

```bash
git merge-base <branch1> <branch2>
```

### 批次刪除符合 pattern 的 tag

```bash
# 刪除本地 tag
git tag -l "D4.0040*" | xargs git tag -d

# 刪除遠端 tag（以下兩種寫法皆可）

# 寫法 1：較直觀（Git 1.7.0+）
git push origin --delete D4.0040.0-a D4.0040.0-b D4.0040.0-c

# 寫法 2：底層 refspec 語法，適合搭配 xargs 批次處理
git tag -l "D4.0040*" | xargs -I {} git push origin :refs/tags/{}
```

---

## 建議做法

1. **正式版本 tag**（如 `v4.0039.1`）應該打在 `master` 分支上，不會受 feature 分支 rebase 影響
2. **開發用 tag**（如 `D4.0040.0-a`）在 rebase 後通常不再需要，可以刪除
3. 如果 tag 很重要，**rebase 前先記錄 tag 與 commit message 的對應關係**

---

## 什麼是 Refspec？

Refspec（Reference Specification）是 Git 定義「本地與遠端 ref 對應關係」的格式。

### 基本語法

```
<src>:<dst>
```

- `src`：來源（本地）
- `dst`：目標（遠端）

### 範例

| 指令 | 意思 |
|------|------|
| `git push origin main:main` | 把本地 main 推到遠端 main |
| `git push origin main:develop` | 把本地 main 推到遠端 develop |
| `git push origin :refs/tags/v1.0` | 推送「空」到遠端 = 刪除遠端的 v1.0 tag |

### 為什麼 `:refs/tags/v1.0` 能刪除？

```
<空>:refs/tags/v1.0
  ↑       ↑
 來源    目標
(空的)  (遠端tag)
```

來源是空的，等於告訴 Git：「用空的東西覆蓋遠端的這個 ref」→ 刪除。

### 完整 refspec 格式

```
+<src>:<dst>
```

前面的 `+` 表示強制更新（類似 `--force`）。

---

## 相關指令比較

| 指令 | 用途 | 會修改 repo 嗎？ |
|------|------|------------------|
| `git merge-base` | 查詢兩分支的共同祖先 | 否（只查詢） |
| `git rebase` | 重新整理 commit 歷史 | 是 |
| `git tag` | 建立/查看/刪除 tag | 是（建立/刪除時） |
