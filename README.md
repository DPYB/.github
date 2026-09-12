# DPYB 개발 핸드북

DPYB 조직의 모든 레포에 공통으로 적용되는 개발 규칙 모음입니다.
이 레포(`.github`)는 조직 전체 기본값(PR 템플릿, 프로필 등)을 제공하며, 각 레포는 필요 시 자체 파일로 이 기본값을 덮어쓸 수 있습니다.

## 목차

1. [네이밍 규칙](./docs/01-naming-rules.md) — 레포/브랜치/코드 네이밍 표준
2. [Git 컨벤션](./docs/02-git-conventions.md) — 브랜치 전략, 커밋 메시지 규칙
3. [바이브 코딩 하네스](./docs/03-vibe-coding-harness.md) — AI 에이전트(Codex, Claude Code, Antigravity, Kiro)와 함께 작업하기 위한 공통 설정
4. [무과금 배포 정책](./docs/04-deployment-policy.md) — Render/Supabase/Cloudflare 우선, GCP 무료 크레딧 폴백 (로컬 전체 스택 테스트 우선)

## 이 레포가 자동으로 적용하는 것

- **PR 템플릿**: 자체 `pull_request_template.md`가 없는 레포는 [`.github/pull_request_template.md`](./.github/pull_request_template.md)을 자동으로 사용합니다.
- **기여 가이드 / 보안 정책**: [`.github/CONTRIBUTING.md`](./.github/CONTRIBUTING.md), [`.github/SECURITY.md`](./.github/SECURITY.md)도 자체 파일이 없는 레포에 기본값으로 적용됩니다.
- **조직 프로필**: [`profile/README.md`](./profile/README.md)가 github.com/DPYB 조직 페이지에 표시됩니다.
- **공통 CI 워크플로우**: [`.github/workflows/reusable-python-ci.yml`](./.github/workflows/reusable-python-ci.yml)을 통해 모든 백엔드 서비스 레포(`backend-*`)에서 Python 3.12 린트/타입체크/테스트를 원격 호출(`uses:`)하여 재사용합니다.
- **공통 PR & 커밋 린터**: [`.github/workflows/reusable-pr-lint.yml`](./.github/workflows/reusable-pr-lint.yml)을 통해 모든 서비스 레포에서 PR 제목, 브랜치명, 커밋 메시지 컨벤션을 자동 검증합니다.
- **중앙 킵얼라이브 크론**: [`.github/workflows/keep-alive.yml`](./.github/workflows/keep-alive.yml)을 통해 10분마다 백엔드 서비스들(`core-api`, `ai-agent`, `auth-api`)의 `/health`를 한 번에 핑하여 Render 웹서비스(15분) 및 Supabase(7일) 슬립을 중앙에서 방지합니다.

## 조직 내 다른 레포에 적용하는 방법

### 1. 자동 상속 (별도 설정 불필요)
* **PR 템플릿**: 각 레포에 자체 `pull_request_template.md`가 없으면 GitHub이 이 레포의 템플릿을 자동으로 불러옵니다.
* **기여 가이드 및 보안 정책**: `CONTRIBUTING.md`, `SECURITY.md`도 하위 레포에 자체 파일이 없을 경우 조직 기본값으로 작동합니다.

### 2. 재사용 워크플로우 호출 (각 레포에 단 10줄 추가)

#### 백엔드 CI (`backend-*` 레포의 `.github/workflows/ci.yml`)
```yaml
name: CI

on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop, main]

jobs:
  ci:
    uses: DPYB/.github/.github/workflows/reusable-python-ci.yml@main
    with:
      python-version: "3.12"
```

#### PR & 커밋 컨벤션 검증 (모든 서비스 레포의 `.github/workflows/lint-pr.yml`)
```yaml
name: Lint PR

on:
  pull_request:
    types: [opened, edited, synchronize, reopened]

jobs:
  lint:
    uses: DPYB/.github/.github/workflows/reusable-pr-lint.yml@main
```

### 3. 브랜치 보호 규칙(Branch Protection Rule) 설정 (머지 강제 방지)

> ⚠️ GitHub Actions 워크플로우는 검사 결과만 제공할 뿐, GitHub 저장소 설정에서 필수 체크로 등록하지 않으면 실패한 상태에서도 실수로 머지될 수 있습니다. 각 서비스 레포 생성 시 아래 설정을 필수로 활성화합니다.

1. 대상 레포의 **Settings → Branches** (또는 Rulesets) 메뉴로 이동합니다.
2. `Branch protection rules`에서 **Add rule**을 누르고 Branch name pattern에 `develop`과 `main`을 각각 등록합니다.
3. 아래 핵심 보안/품질 옵션을 활성화합니다:
   - **Require a pull request before merging**: 브랜치 직접 푸시 금지, PR 필수화.
   - **Require approvals (최소 1명)** ⭐️ **핵심 물리적 잠금장치**:
     - GitHub은 PR 작성자의 Self-Approve를 차단하므로, 에이전트(또는 로컬 CLI 토큰)가 `gh pr merge` 등으로 자율 머지하는 것을 시스템 차원에서 원천 차단합니다.
     - **`main`**: 프로덕션 보호를 위해 **필수 활성화 (1명)**.
     - **`develop`**: 1~2인 소규모 개발 시 병목이 된다면 셀프 리뷰 습관 또는 보조 계정을 활용하고, 여건에 맞춰 선택 적용합니다.
   - **Require status checks to pass before merging**: 체크가 통과되어야만 머지 버튼 활성화.
     - Status check 검색창에서 등록된 검사 Job 이름을 검색해 필수로 체크:
       - `Validate PR & Commit Conventions` (PR 및 커밋 컨벤션 검사)
       - `Lint, Type Check & Test` (백엔드 CI 테스트 및 린트)
   - **Require branches to be up to date before merging** (선택 권장): 베이스 브랜치(`develop`)가 자주 갱신될 때 계속 리베이스해야 하는 오버헤드가 있다면 소규모 팀 상황에 맞춰 유연하게 끄셔도 좋습니다.

### 4. 인간 개입 지점 (머지 권한)
* AI 에이전트는 계획 수립, 코드 구현, 테스트 실행, 커밋, PR 오픈까지만 지원합니다.
* **`develop` 및 `main` 브랜치로의 최종 PR 머지 버튼은 어떠한 경우에도 에이전트가 누르지 않으며, 반드시 사람이 직접 diff와 체크 결과를 확인 후 클릭합니다.**
