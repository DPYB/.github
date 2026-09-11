# 03. 바이브 코딩 하네스

팀원마다 사용하는 AI 코딩 툴이 다르기 때문에(Codex, Claude Code, Antigravity(AGY), Kiro), **어떤 툴로 세션을 열어도 동일한 컨텍스트와 워크플로우로 이어받을 수 있도록** 모든 서비스 레포(`backend-*`, `frontend-*`)가 아래 구조를 공통으로 가져간다.

이 체계는 `backend-book`에서 실전 검증된 6-문서 하네스를 조직 표준으로 일반화한 것이다.

**Jira/Confluence 등 외부 무거운 도구는 쓰지 않는다.** 모든 작업 계획, 할 일, 결정 이력은 레포 내 `.harness/`(`PLAN.md`, `BACKLOG.md`, `DECISIONS.md`)로 100% 자체 완결한다.

> ⚠️ 이 표준은 `.github` 레포 안에 있을 뿐 GitHub이 자동으로 각 서비스 레포에 적용해주는 건 아니다. 새 레포를 만들 때 아래 템플릿을 직접 복사해서 반영해야 한다.

```
{repo-root}/
├── AGENTS.md              # 실질적 규칙집 — 읽기 순서, 문서 소유권, 워크플로우 사이클 (Codex, Antigravity 공용)
├── CLAUDE.md               # Claude Code용 — "AGENTS.md를 따르라"는 얇은 어댑터
├── .kiro/
│   └── steering/
│       └── project.md      # Kiro용 — "AGENTS.md를 따르라"는 얇은 어댑터
└── .harness/
    ├── HANDOFF.md           # 세션별 서술형 로그 (append-only)
    ├── STATE.md             # 완료된 것의 단계 단위 스냅샷
    ├── ARCHITECTURE.md      # 지금 시점의 기술 스택/구조/컨벤션 (레포별 실제 내용)
    ├── PLAN.md              # 아직 안 끝난 계획 + 체크리스트만
    ├── DECISIONS.md         # 중요 결정과 이유 (append-only, 최신이 최상단)
    └── BACKLOG.md           # 지금 안 하지만 나중에 할 것
```

> ⚠️ 툴마다 세부 지원 방식이 계속 바뀌는 영역이라, 새 툴 도입 시 실제 동작(하위 폴더까지 읽는지, 루트만 보는지)을 한 번 확인하고 이 문서를 갱신할 것.

## 왜 문서 하나가 아니라 6개로 쪼개는가

문서 하나에 모든 걸 적으면 "이 내용을 어디에 적어야 하나"를 매번 판단해야 하고, 결국 같은 정보가 여러 곳에 중복/불일치하게 된다. 문서마다 **단일 소유권**을 강제하면 이 문제가 사라진다.

| 문서 | 담는 내용 (단일 소유) | 담지 않는 내용 |
| :--- | :--- | :--- |
| `HANDOFF.md` | 세션마다 무엇을 했는지 서술형 로그 (append-only) | 단계별 완료 요약(STATE 몫), 결정 이유(DECISIONS 몫) |
| `STATE.md` | 지금까지 끝난 기능의 단계 단위 한 줄 스냅샷 | 세션별 서술(HANDOFF 몫). 이슈 하나하나를 로그처럼 쌓지 않는다 |
| `ARCHITECTURE.md` | 현재 시점의 기술 스택, 폴더 구조, 코딩 컨벤션 (현재 상태) | 왜 그렇게 정했는지(DECISIONS 몫), 진행 중인 계획(PLAN 몫) |
| `DECISIONS.md` | 중요한 아키텍처/기술적 결정 내용과 그 이유 (append-only) | 구현 여부나 진행 상황(STATE 몫) |
| `PLAN.md` | 아직 안 끝난 계획과 체크리스트만 유지 | 완료된 항목 (체크만 남기지 말고 STATE로 옮긴 뒤 제거) |
| `BACKLOG.md` | 지금 하지 않지만 나중에 할 기술부채, 버그, 아이디어 | 현재 진행 중인 계획(PLAN 몫) |

## 작업 워크플로우 (필수)

- **계획 수립 우선**: 새로운 기능/변경 요청을 받으면 바로 코드를 고치지 말고 `.harness/PLAN.md`에 계획 초안을 작성해 사용자에게 제시한다. (단순 질의응답, 사소한 오탈자 수정은 계획 없이 바로 가능)
- **사용자 승인 후 구현**: 사용자가 명시적으로 컨펌하면 구현을 시작한다. 구현 방식(TDD 등)은 레포 특성에 맞는 개발 사이클을 따르되, "확인 → 구현 → 기록"의 순서 자체는 모든 레포 공통으로 강제한다.
- **점진적 반영**: `PLAN.md`의 세부 체크리스트가 완료될 때마다 즉시 `.harness/STATE.md`에 한 줄로 반영하고 `PLAN.md`에서 제거한다.
- **세션 종료/인수인계**: 작업을 중단하거나 세션을 종료할 때 반드시 `.harness/HANDOFF.md`에 다음 세션을 위한 인수인계 서술을 남긴다.
- **중요 결정 기록**: 아키텍처나 정책의 중요한 결정은 `.harness/DECISIONS.md` 표 최상단에 이유와 함께 기록한다.
- **커밋**: 사용자가 명시적으로 요청했을 때만 수행하며, 변경된 파일만 선별해 스테이징한다.

## `AGENTS.md` 템플릿 (레포 루트, 실질적 규칙집)

레포별로 기술 스택이 다르므로 아래 뼈대에서 스택 관련 세부 정책만 채워 넣는다. 브랜치/커밋/배포 정책은 조직 표준([02-git-conventions.md](./02-git-conventions.md), [04-deployment-policy.md](./04-deployment-policy.md))을 그대로 링크하고 여기 다시 적지 않는다.

```markdown
# AGENTS.md — 개발 하네스 지침

## 1. 세션 시작 시 필수 읽기 순서
어떤 AI 도구(Claude Code, Codex, Antigravity, Kiro 등)로 세션을 시작하든 아래 순서대로 먼저 읽는다:
1. `.harness/HANDOFF.md` — 직전 세션이 어디서 멈췄는지
2. `.harness/STATE.md` — 지금까지 무엇이 완료되었는지
3. `.harness/ARCHITECTURE.md` — 기술 스택/폴더 구조/컨벤션
4. `.harness/PLAN.md` — 현재 진행 중이거나 제안된 계획
5. 필요 시 `.harness/DECISIONS.md`(과거 결정 이유), `.harness/BACKLOG.md`(미해결 부채)

## 2. 문서별 책임
[본 문서(03-vibe-coding-harness.md)의 표 참고 — 중복 기록 금지]

## 3. 작업 워크플로우
[본 문서(03-vibe-coding-harness.md)의 "작업 워크플로우" 참고]

## 4. 이 레포 고유 정책
{DB, 테스트, 배포 등 이 레포만의 정책 — 상세 내용은 `.harness/ARCHITECTURE.md`를 참고}

## 5. 브랜치 & 커밋 컨벤션
[DPYB `.github` 레포의 02-git-conventions.md](https://github.com/DPYB/.github/blob/main/docs/02-git-conventions.md)를 따른다.

## 6. 배포
[DPYB `.github` 레포의 04-deployment-policy.md](https://github.com/DPYB/.github/blob/main/docs/04-deployment-policy.md)를 따른다.
```

## `CLAUDE.md` / `.kiro/steering/project.md` (얇은 어댑터)

```markdown
# CLAUDE.md

이 프로젝트의 규칙과 워크플로우는 [AGENTS.md](./AGENTS.md)를 따른다.
```

```markdown
---
inclusion: always
---

# Project Steering

이 프로젝트의 규칙과 워크플로우는 [AGENTS.md](../../AGENTS.md)를 따른다.
```

## `.harness/` 초기 템플릿

### `HANDOFF.md`
```markdown
# HANDOFF (세션별 서술 로그, append-only)

## YYYY-MM-DD: 프로젝트 초기 세팅
- {이번 세션에서 한 일}

**다음 세션 시작 시**: {다음에 확인/진행할 것}
```

### `STATE.md`
```markdown
# STATE (완료 스냅샷)

단계가 끝나면 그 단계를 한 줄로 갱신한다. 세션별 서술은 `HANDOFF.md`에 남긴다.

## 완료된 단계
- {완료된 기능/마일스톤 한 줄 요약}
```

### `ARCHITECTURE.md`
```markdown
# ARCHITECTURE (현재 상태)

이 문서는 지금 시점의 실제 기술 스택·구조·컨벤션만 담는다. 결정 이유는 `DECISIONS.md`, 진행 상황은 `STATE.md`를 본다.

## 기술 스택
{언어/프레임워크/DB 등}

## 저장소 구조
{핵심 폴더만 간단히}

## 이 레포 고유 정책
{DB 스키마 격리, 인증 방식, 캐싱 전략 등}
```

### `PLAN.md`
```markdown
# PLAN (미완료 계획)

완료된 항목은 여기 체크만 남기지 않고 `STATE.md`로 옮긴 뒤 이 문서에서 제거한다.

## {진행 중인 작업명}
- [ ] {단계 1}
- [ ] {단계 2}
```

### `DECISIONS.md`
```markdown
# DECISIONS (결정 히스토리, 최신 결정이 최상단)

결정 내용과 이유만 기록한다. 진행 상황은 `STATE.md`를 본다.

| 날짜 | 결정 | 이유 / 대안 비교 |
| :--- | :--- | :--- |
| YYYY-MM-DD | {결정} | {이유} |
```

### `BACKLOG.md`
```markdown
# BACKLOG (미해결 항목 및 기술 부채)

지금 하지 않지만 나중에 할 것들을 기록한다. 진행 중인 계획은 `PLAN.md`에 둔다.

- [ ] {항목}
```

## 새 레포에 적용하는 방법

1. 레포 루트에 `AGENTS.md` 생성 (위 템플릿에서 "이 레포 고유 정책"만 채움).
2. `CLAUDE.md`, `.kiro/steering/project.md` 얇은 어댑터 생성.
3. `.harness/` 폴더에 6개 초기 템플릿 생성.
4. AI 에이전트에게 첫 명령: **"`AGENTS.md`의 하네스 지침을 읽고, `.harness/PLAN.md`의 첫 번째 체크리스트부터 구현 계획을 세워줘."**

## 운영 원칙

- `.harness/STATE.md`, `PLAN.md`, `HANDOFF.md`는 PR 템플릿 체크리스트에 포함되어 있으므로 매 PR마다 갱신 여부를 확인한다.
- 툴을 바꿔서 이어받는 팀원은 `AGENTS.md`의 읽기 순서(`HANDOFF` → `STATE` → `ARCHITECTURE` → `PLAN`)만 따라가면 컨텍스트를 따라잡을 수 있어야 한다.
- 레포별 세부 내용(`.harness/` 안의 실제 텍스트, `AGENTS.md`의 "이 레포 고유 정책")은 이 핸드북이 아니라 **각 서비스 레포 안**에 위치한다 — 이 문서는 구조·포맷·워크플로우만 표준화한다.
