#!/bin/bash
# =========================================================
# Bigcapital 上游跟踪 & 合并工具
# 
# 用途：跟踪上游 bigcapitalhq/bigcapital 的更新，
# 自动合并到本地 Fork，并重建 Docker 镜像
# 
# 用法：
#   ./scripts/upstream-tracker.sh check    # 检查上游是否有新提交
#   ./scripts/upstream-tracker.sh merge    # 合并上游更新到本地
#   ./scripts/upstream-tracker.sh status   # 查看当前状态
# =========================================================
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM_REMOTE="upstream"
FORK_REMOTE="origin"
ZH_BRANCH="zh-CN"
MAIN_BRANCH="develop"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_upstream() {
    echo -e "${YELLOW}[*] Checking upstream for new commits...${NC}"
    
    # Fetch upstream
    git fetch $UPSTREAM_REMOTE $MAIN_BRANCH 2>/dev/null || {
        echo -e "${RED}[!] Upstream remote not found. Setting up...${NC}"
        git remote add $UPSTREAM_REMOTE https://github.com/bigcapitalhq/bigcapital.git
        git fetch $UPSTREAM_REMOTE $MAIN_BRANCH
    }
    
    UPSTREAM_HASH=$(git rev-parse $UPSTREAM_REMOTE/$MAIN_BRANCH)
    LOCAL_HASH=$(git rev-parse $MAIN_BRANCH)
    
    if [ "$UPSTREAM_HASH" = "$LOCAL_HASH" ]; then
        echo -e "${GREEN}[✓] Fork is up to date with upstream.${NC}"
    else
        echo -e "${YELLOW}[!] Upstream has new commits!${NC}"
        echo "  Local:  $(git log --oneline -1 $MAIN_BRANCH)"
        echo "  Remote: $(git log --oneline -1 $UPSTREAM_REMOTE/$MAIN_BRANCH)"
        echo ""
        echo "  Commits behind:"
        git log --oneline $MAIN_BRANCH..$UPSTREAM_REMOTE/$MAIN_BRANCH
    fi
}

merge_upstream() {
    echo -e "${YELLOW}[*] Merging upstream changes...${NC}"
    
    # Ensure upstream remote exists
    git remote get-url $UPSTREAM_REMOTE 2>/dev/null || {
        git remote add $UPSTREAM_REMOTE https://github.com/bigcapitalhq/bigcapital.git
    }
    
    # Fetch latest
    git fetch $UPSTREAM_REMOTE $MAIN_BRANCH
    
    # Check if we're on zh-CN branch or develop
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    if [ "$CURRENT_BRANCH" = "$ZH_BRANCH" ]; then
        echo -e "${YELLOW}[*] On zh-CN branch. Merging upstream into $MAIN_BRANCH first...${NC}"
        
        # Stash any local changes
        git stash push -m "auto-stash-before-merge" 2>/dev/null || true
        
        # Switch to develop and merge
        git checkout $MAIN_BRANCH
        git merge $UPSTREAM_REMOTE/$MAIN_BRANCH --no-edit || {
            echo -e "${RED}[!] Merge conflict in $MAIN_BRANCH. Resolve manually.${NC}"
            exit 1
        }
        
        # Switch back to zh-CN and merge develop
        git checkout $ZH_BRANCH
        git merge $MAIN_BRANCH --no-edit || {
            echo -e "${RED}[!] Merge conflict in $ZH_BRANCH. Resolve manually.${NC}"
            echo ""
            echo "Common conflict areas (zh-CN files):"
            echo "  - packages/webapp/src/lang/zh-CN/index.json"
            echo "  - packages/webapp/src/lang/zh-CN/locale.tsx"
            echo "  - packages/webapp/src/components/AppIntlLoader.tsx"
            echo "  - packages/webapp/src/constants/languagesOptions.tsx"
            exit 1
        }
        
        # Restore stash
        git stash pop 2>/dev/null || true
        
    elif [ "$CURRENT_BRANCH" = "$MAIN_BRANCH" ]; then
        git merge $UPSTREAM_REMOTE/$MAIN_BRANCH --no-edit || {
            echo -e "${RED}[!] Merge conflict. Resolve manually.${NC}"
            exit 1
        }
    else
        echo -e "${RED}[!] Unexpected branch: $CURRENT_BRANCH${NC}"
        echo "Expected: $MAIN_BRANCH or $ZH_BRANCH"
        exit 1
    fi
    
    echo -e "${GREEN}[✓] Upstream merged successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review conflicts (if any)"
    echo "  2. Update zh-CN translations for new/updated strings"
    echo "  3. git push origin $ZH_BRANCH"
    echo "  4. Rebuild Docker image"
}

show_status() {
    echo -e "${YELLOW}=== Bigcapital Fork Status ===${NC}"
    echo ""
    
    # Branches
    echo "Branches:"
    git branch -a | grep -E "($MAIN_BRANCH|$ZH_BRANCH)" | head -5
    echo ""
    
    # Upstream
    if git remote get-url $UPSTREAM_REMOTE 2>/dev/null; then
        echo "Upstream: $(git remote get-url $UPSTREAM_REMOTE)"
        git fetch $UPSTREAM_REMOTE $MAIN_BRANCH --quiet 2>/dev/null
        BEHIND=$(git rev-list --count $MAIN_BRANCH..$UPSTREAM_REMOTE/$MAIN_BRANCH 2>/dev/null || echo "0")
        echo "Commits behind upstream: $BEHIND"
    else
        echo "Upstream: NOT CONFIGURED"
    fi
    echo ""
    
    # Fork remote
    echo "Fork: $(git remote get-url $FORK_REMOTE 2>/dev/null || echo 'NOT CONFIGURED')"
}

case "${1:-status}" in
    check)
        check_upstream
        ;;
    merge)
        merge_upstream
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {check|merge|status}"
        exit 1
        ;;
esac
