# Git 分支管理指南

本文件整理了團隊常用的 Git 分支管理方式，以純 Git 指令實作 GitFlow 工作流程，供大家參考使用。

---

## 目錄

1. [工作流程選擇指南](#工作流程選擇指南)
2. [GitFlow 工作流程](#gitflow-工作流程)
3. [GitHub Flow 工作流程](#github-flow-工作流程)
4. [Git Alias 設定（選用）](#git-alias-設定選用)
5. [常用指令速查](#常用指令速查)

---

## 工作流程選擇指南

### GitFlow 適用情境

- 有明確的版本發佈週期（如：每 1-4 週發佈一次）
- 需要同時維護多個版本
- 需要 release 分支進行整合測試、版本號調整、文件更新
- 產品需要穩定的正式環境，hotfix 須獨立處理
- 多個功能需累積後一次發佈

### GitHub Flow 適用情境

- 持續部署（Continuous Deployment）的專案
- 小型專案或快速迭代的產品
- 功能完成即可部署，無需等待版本週期
- 團隊規模較小，溝通成本低

---

## GitFlow 工作流程

### 分支說明

| 分支類型 | 命名規則 | 說明 |
|---------|---------|------|
| master | `master` | 正式環境程式碼，僅透過 release 或 hotfix 合併 |
| develop | `develop` | 開發主線，所有 feature 合併至此 |
| feature | `feature/{功能名稱}` | 新功能開發分支 |
| release | `release/{版本號}` | 發佈準備分支，用於整合測試與版本調整 |
| hotfix | `hotfix/{版本號}-hotfix{序號}` | 緊急修復分支 |

### 初始設定

#### 新專案

```bash
git init
git remote add origin {GitLab Repository URI}
git add .
git commit -m "Initial commit"
git push -u origin master

# 建立 develop 分支
git checkout -b develop
git push -u origin develop
```

#### Clone 既有專案

```bash
git clone {GitLab Repository URI}
cd {project-name}
git checkout -b develop origin/develop
```

---

### Feature 開發流程

#### 1. 建立 Feature 分支

```bash
git fetch origin
git checkout develop
git pull origin develop
git checkout -b "feature/{功能名稱}"
```

> 功能名稱建議使用簡短的需求描述，如：`feature/user-login`、`feature/export-report`

#### 2. 開發過程中同步 develop

```bash
git checkout develop
git pull origin develop
git checkout "feature/{功能名稱}"
git rebase develop
```

> 若有衝突，解決後執行 `git rebase --continue`

#### 3. 提交變更

```bash
git add .
git commit -m "{Commit Message}"
```

#### 4. 推送至 GitLab（建立 Merge Request）

```bash
git push -u origin "feature/{功能名稱}"
```

在 GitLab 上建立 Merge Request，指定合併至 `develop` 分支，經 Code Review 後合併。

#### 5. 合併後清理（本地）

```bash
git checkout develop
git pull origin develop
git branch -d "feature/{功能名稱}"
```

---

### Release 發佈流程

#### 1. 建立 Release 分支

確認所有預計發佈的 feature 皆已合併至 develop。

```bash
git fetch origin
git checkout develop
git pull origin develop
git checkout -b "release/{版本號}"
```

#### 2. Release 分支上的作業

- 更新版本號
- 更新 CHANGELOG
- 整合測試與修復

```bash
git add .
git commit -m "Prepare release {版本號}"
```

#### 3. 完成 Release

```bash
# 合併至 master
git checkout master
git pull origin master
git merge "release/{版本號}" --no-ff -m "Release {版本號}"
git tag -a "{版本號}" -m "Release {版本號}"

# 合併回 develop（保留 release 期間的修復）
git checkout develop
git pull origin develop
git merge "release/{版本號}" --no-ff -m "Merge release/{版本號} back to develop"

# 刪除 release 分支
git branch -d "release/{版本號}"

# 推送
git push origin master develop --tags
```

---

### Hotfix 緊急修復流程

#### 1. 建立 Hotfix 分支

```bash
git checkout master
git pull origin master
git checkout -b "hotfix/{版本號}-hotfix{序號}"
```

#### 2. 修復並提交

```bash
git add .
git commit -m "Hotfix: {修復說明}"
```

#### 3. 完成 Hotfix

```bash
# 合併至 master
git checkout master
git merge "hotfix/{版本號}-hotfix{序號}" --no-ff -m "Merge hotfix/{版本號}-hotfix{序號}"
git tag -a "{版本號}-hotfix{序號}" -m "Hotfix: {修復說明}"

# 合併至 develop
git checkout develop
git pull origin develop
git merge "hotfix/{版本號}-hotfix{序號}" --no-ff -m "Merge hotfix to develop"

# 刪除 hotfix 分支
git branch -d "hotfix/{版本號}-hotfix{序號}"

# 推送
git push origin master develop --tags
```

> 若目前有進行中的 release 分支，hotfix 也需合併至該 release 分支。

---

## GitHub Flow 工作流程

適用於持續部署的專案，流程簡化為：

```
main ← feature branch ← Merge Request ← merge ← deploy
```

### 流程步驟

#### 1. 從 main 建立 feature 分支

```bash
git checkout main
git pull origin main
git checkout -b "feature/{功能名稱}"
```

#### 2. 開發並提交

```bash
git add .
git commit -m "{Commit Message}"
git push -u origin "feature/{功能名稱}"
```

#### 3. 建立 Merge Request

在 GitLab 上建立 MR，經 Code Review 後合併至 main。

#### 4. 合併後自動部署

合併至 main 後，透過 CI/CD Pipeline 自動部署。

#### 5. 清理本地分支

```bash
git checkout main
git pull origin main
git branch -d "feature/{功能名稱}"
```

---

## Git Alias 設定（選用）

在 `~/.gitconfig` 加入以下設定，簡化常用操作：

```ini
[alias]
    # Feature
    feature-start = "!f() { git checkout develop && git pull && git checkout -b feature/$1; }; f"
    feature-push = "!f() { git push -u origin $(git branch --show-current); }; f"

    # Release
    release-start = "!f() { git checkout develop && git pull && git checkout -b release/$1; }; f"

    # Hotfix
    hotfix-start = "!f() { git checkout master && git pull && git checkout -b hotfix/$1; }; f"

    # 常用
    sync = "!f() { git fetch origin && git pull origin $(git branch --show-current); }; f"
    cleanup = "!f() { git branch --merged | grep -v '\\*\\|master\\|develop\\|main' | xargs -n 1 git branch -d; }; f"
```

使用範例：

```bash
git feature-start user-login    # 建立 feature/user-login 分支
git feature-push                # 推送當前分支至 origin
git release-start 1.2.0         # 建立 release/1.2.0 分支
git hotfix-start 1.2.0-hotfix1  # 建立 hotfix 分支
git sync                        # 同步當前分支
git cleanup                     # 清理已合併的本地分支
```

---

## 常用指令速查

### 分支操作

```bash
# 查看所有分支
git branch -a

# 刪除本地分支
git branch -d {branch-name}

# 刪除遠端分支
git push origin --delete {branch-name}

# 追蹤遠端分支
git checkout -b {local-branch} origin/{remote-branch}
```

### Tag 操作

```bash
# 建立標籤
git tag -a "{版本號}" -m "{說明}"

# 查看所有標籤
git tag -l

# 搜尋標籤
git tag -l --format='%(refname:short): %(subject)' | grep -i '{關鍵字}'

# 查看標籤詳細資訊
git show {tag-name}

# 推送標籤
git push origin --tags
```

### 其他

```bash
# 查看提交歷史（圖形化）
git log --oneline --graph --all

# 暫存目前變更
git stash
git stash pop

# 取消最後一次提交（保留變更）
git reset --soft HEAD~1
```

---

## 小提醒

1. **feature finish 是「準備部署」而非「完成開發」**
   - 合併至 develop 代表該功能已準備好進入下次 release

2. **建議使用 `--no-ff` 保留合併紀錄**
   - 多次提交的分支合併時使用 `--no-ff`，可保留完整的分支歷史

3. **善用 Merge Request 進行 Code Review**
   - 在 GitLab 上透過 MR 進行程式碼審查，有助於確保程式碼品質

4. **建議定期同步 develop 分支**
   - 開發 feature 期間定期 rebase develop，可減少合併衝突

5. **建議用 Tag 標記每次正式發佈**
   - 方便追蹤版本歷史與快速回溯

---

## 參考資料

- [A successful Git branching model](https://nvie.com/posts/a-successful-git-branching-model/) - GitFlow 原始提案
- [GitLab Flow](https://docs.gitlab.com/ee/topics/gitlab_flow.html) - GitLab 官方建議的工作流程
- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow) - 簡化的持續部署流程
