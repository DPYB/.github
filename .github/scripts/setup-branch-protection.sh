#!/usr/bin/env bash
# ==============================================================================
# setup-branch-protection.sh
#
# DPYB 서비스 레포지토리의 머지 전략(Squash 단일화 & 메시지 자동화)과
# develop 및 main 브랜치 보호 규칙(Branch Protection)을
# GitHub API(gh api)를 통해 멱등성(Idempotent) 있게 일괄 설정하는 스크립트입니다.
#
# [주요 특징 및 안전성]
# 1. 머지 전략 자동화:
#    - Squash and merge 단일화 (Merge commit, Rebase 비활성화)
#    - PR 제목(`타입[적용범위]: 요약`)을 단일 커밋 제목으로 자동 매핑
#    - 커밋 본문(Extended description)은 기본 빈칸으로 설정 (컨벤션 완벽 일치)
#    - 머지 완료 시 피처 브랜치 자동 삭제 (Head branch auto deletion)
# 2. 멱등성(Idempotent): gh api 방식으로 동작하므로 여러 번 실행해도
#    기존 규칙을 안전하게 갱신(덮어쓰기)하며 중복 생성 부작용이 없습니다.
# 3. 히스토리 보존: 이미 커밋/푸시가 진행된 레포에 실행해도 기존 git 히스토리에는
#    일체 영향이 없으며, 설정 시점 이후의 PR 머지 및 브랜치 푸시부터 규제합니다.
# 4. 필수 상태 검사 (Status Checks):
#    - PR & 커밋 컨벤션: "lint / Validate PR & Commit Conventions"
#    - 백엔드 CI (린트/타입/테스트): "ci / Lint, Type Check & Test"
#    ※ 실제 워크플로우 실행 시 등록되는 컨텍스트 이름과 100% 일치해야 합니다.
#
# [사용법]
#   ./.github/scripts/setup-branch-protection.sh <레포이름>
#   예: ./.github/scripts/setup-branch-protection.sh backend-ai-agent
# ==============================================================================

set -euo pipefail

ORG="DPYB"
REPO_NAME="${1:-}"

if [[ -z "$REPO_NAME" ]]; then
  echo "❌ [오류] 대상 레포지토리 이름을 입력해주세요."
  echo "사용법: $0 <레포이름>"
  echo "예시: $0 backend-ai-agent"
  exit 1
fi

FULL_REPO="${ORG}/${REPO_NAME}"
echo "=========================================================="
echo "🛡️  브랜치 보호 규칙 설정 대상: ${FULL_REPO}"
echo "=========================================================="

# 레포지토리 존재 확인
if ! gh repo view "$FULL_REPO" >/dev/null 2>&1; then
  echo "❌ [오류] 저장소 '${FULL_REPO}'를 찾을 수 없거나 접근 권한이 없습니다."
  exit 1
fi

# 원격 브랜치 목록 가져오기
EXISTING_BRANCHES=$(gh api "repos/${FULL_REPO}/branches" --jq '.[].name' 2>/dev/null || true)

has_branch() {
  local target="$1"
  echo "$EXISTING_BRANCHES" | grep -qx "$target"
}

# 0. 레포지토리 전역 머지 전략 설정 (Squash 단일화 & 커밋 메시지 자동화)
# - Allow merge commits: false (일반 머지 커밋 차단)
# - Allow rebase merging: false (리베이스 머지 차단)
# - Allow squash merging: true (Squash 머지만 허용)
# - Squash commit title: PR_TITLE (PR 제목이 커밋 메시지 제목으로 자동 입력)
# - Squash commit message: BLANK (Extended description 본문은 기본 빈칸)
# - Automatically delete head branches: true (머지 완료 시 피처 브랜치 자동 삭제)
echo "⚙️  레포지토리 전역 머지 전략을 설정합니다..."
gh api -X PATCH "repos/${FULL_REPO}" \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F allow_squash_merge=true \
  -F squash_merge_commit_title="PR_TITLE" \
  -F squash_merge_commit_message="BLANK" \
  -F delete_branch_on_merge=true >/dev/null
echo "✅ 레포지토리 머지 전략 (Squash 단일화, PR 제목/빈칸 기본값, 브랜치 자동 삭제) 설정 완료!"

# 1. develop 브랜치 보호 규칙 설정
# - PR 필수 (직접 푸시 차단)
# - 상태 검사 통과 필수 (컨벤션 linter + CI)
# - 승인 리뷰 수: 0 (1~2인 개발 환경에서 머지 병목 방지, 필요 시 웹에서 상향 가능)
if has_branch "develop"; then
  echo "⚙️  'develop' 브랜치 보호 규칙을 설정합니다..."
  gh api -X PUT "repos/${FULL_REPO}/branches/develop/protection" \
    --input - << 'EOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "lint / Validate PR & Commit Conventions",
      "ci / Lint, Type Check & Test"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
  echo "✅ 'develop' 브랜치 보호 설정 완료!"
else
  echo "ℹ️  'develop' 브랜치가 아직 존재하지 않아 건너뜁니다. (브랜치 생성 후 재실행 가능)"
fi

# 2. main 브랜치 보호 규칙 설정
# - PR 필수 (직접 푸시 차단)
# - 최소 1명 승인 리뷰 필수 (에이전트 단독 머지 물리적 원천 차단)
# - 상태 검사 통과 필수 (컨벤션 linter + CI)
if has_branch "main"; then
  echo "⚙️  'main' 브랜치 보호 규칙을 설정합니다..."
  gh api -X PUT "repos/${FULL_REPO}/branches/main/protection" \
    --input - << 'EOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "lint / Validate PR & Commit Conventions",
      "ci / Lint, Type Check & Test"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
  echo "✅ 'main' 브랜치 보호 설정 완료!"
else
  echo "ℹ️  'main' 브랜치가 존재하지 않습니다."
fi

echo "🎉 ${FULL_REPO} 브랜치 보호 규칙 설정이 성공적으로 완료되었습니다."
