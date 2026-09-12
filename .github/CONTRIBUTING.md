# Contributing to DPYB

DPYB 조직의 모든 레포에 공통으로 적용되는 기여 가이드입니다. 레포별 세부 사항은 각 레포의 `README.md`, `AGENTS.md`, `.harness/ARCHITECTURE.md`를 따로 확인하세요.

## 시작하기 전에

1. [네이밍 규칙](https://github.com/DPYB/.github/blob/main/docs/01-naming-rules.md)
2. [Git 컨벤션](https://github.com/DPYB/.github/blob/main/docs/02-git-conventions.md)
3. [바이브 코딩 하네스](https://github.com/DPYB/.github/blob/main/docs/03-vibe-coding-harness.md) — AI 에이전트와 함께 작업할 때 필독
4. [무과금 배포 정책](https://github.com/DPYB/.github/blob/main/docs/04-deployment-policy.md)

## 작업 흐름

1. `develop`에서 브랜치를 딴다: `타입/한글-설명` (예: `feature/스크랩-검색-api`)
2. 로컬에서 `docker-compose`로 전체 스택을 띄워 동작을 먼저 확인한다.
3. 커밋은 `<타입>[적용 범위]: <국문 제목>` 형식을 따른다.
4. `develop`을 대상으로 PR을 연다. PR 템플릿의 체크리스트를 빠짐없이 확인한다.
5. AI 에이전트로 작업했다면 `.harness/` 문서(STATE, PLAN, HANDOFF)를 갱신했는지 확인한다.

## 배포

평소 작업은 `develop`에 머무르고, 배포 준비가 되면 `develop` → `main` 승격 PR을 연다. 자세한 내용은 [02-git-conventions.md](https://github.com/DPYB/.github/blob/main/docs/02-git-conventions.md)를 참고한다.
