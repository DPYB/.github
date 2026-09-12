# DPYB 개발 핸드북

DPYB 조직의 모든 레포에 공통으로 적용되는 개발 규칙 모음입니다.
이 레포(`.github`)는 조직 전체 기본값(PR 템플릿, 프로필 등)을 제공하며, 각 레포는 필요 시 자체 파일로 이 기본값을 덮어쓸 수 있습니다.

## 목차

1. [네이밍 규칙](./docs/01-naming-rules.md) — 레포/브랜치/코드 네이밍 표준
2. [Git 컨벤션](./docs/02-git-conventions.md) — 브랜치 전략, 커밋 메시지 규칙
3. [바이브 코딩 하네스](./docs/03-vibe-coding-harness.md) — AI 에이전트(Codex, Claude Code, Antigravity, Kiro)와 함께 작업하기 위한 공통 설정
4. [무과금 배포 정책](./docs/04-deployment-policy.md) — Render/Supabase/Cloudflare 우선, GCP 무료 크레딧 폴백
   ㄴ 로컬에서 모든게 돌아가는것도 우선적으로 테스트 가능해야함

## 이 레포가 자동으로 적용하는 것

- **PR 템플릿**: 자체 `pull_request_template.md`가 없는 레포는 [.github](./pull_request_template.md)을 자동으로 사용합니다.
- **기여 가이드 / 보안 정책**: [`.github/CONTRIBUTING.md`](./.github/CONTRIBUTING.md), [`.github/SECURITY.md`](./.github/SECURITY.md)도 자체 파일이 없는 레포에 기본값으로 적용됩니다.
- **조직 프로필**: [`profile/README.md`](./profile/README.md)가 github.com/DPYB 조직 페이지에 표시됩니다.
- **워크플로우 템플릿** (자동 적용 아님, 수동 선택): [`workflow-templates/`](./workflow-templates/)에 있는 워크플로우는 각 레포의 Actions 탭 → New workflow에서 "Configure"를 눌러야 추가됩니다.
