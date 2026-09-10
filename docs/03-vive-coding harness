# 03. 바이브 코딩 하네스

팀원마다 사용하는 AI 코딩 툴이 다르기 때문에(Codex, Claude Code, Antigravity, Kiro), **실제 컨텍스트는 `.harness/` 폴더 한 곳에 모아두고, 레포 루트에는 툴별 얇은 어댑터 파일만 둔다.** 이렇게 하면 레포 루트가 지저분해지지 않고, 서비스 레포마다 구조가 동일해서 팀원이 어떤 레포에 들어가든 AI와 일하는 방식이 똑같아진다.

```
{repo-root}/
├── CLAUDE.md              # Claude Code용 — .harness/ 참조 한 줄
├── AGENTS.md              # Codex, Antigravity용 — .harness/ 참조 한 줄
├── .kiro/
│   └── steering/
│       └── project.md      # Kiro용 — .harness/ 참조 한 줄
└── .harness/
    ├── ARCHITECTURE.md      # 기술 스택, 디렉토리 구조, 핵심 설계 결정 (안정적, 자주 안 바뀜)
    ├── BACKLOG.md           # 아직 시작 안 한 작업 전체 목록, 우선순위
    ├── PLAN.md              # 지금 진행 중인 작업의 단계별 계획
    ├── STATE.md             # 현재 스냅샷 — 뭐가 되어있고 뭐가 막혀있는지
    └── MEMORY.md            # 장기 기억 — 확정된 결정과 그 이유
```

> ⚠️ 툴마다 세부 지원 방식이 계속 바뀌는 영역이라, 새 툴 도입 시 실제 동작(하위 폴더까지 읽는지, 루트만 보는지)을 한 번 확인하고 이 문서를 갱신할 것.

## 루트 어댑터 파일 — 전부 이 한 줄짜리 패턴

### `AGENTS.md` (Codex, Antigravity 공용)
```markdown
# AGENTS.md

이 프로젝트의 모든 컨텍스트는 [.harness/](./.harness/)에 있다.
작업 시작 전 `.harness/STATE.md` → `.harness/PLAN.md` 순서로 읽고, 필요하면 `.harness/ARCHITECTURE.md`를 참고할 것.
작업 완료 후 `.harness/STATE.md`, `.harness/PLAN.md`, (결정 사항이 있다면) `.harness/MEMORY.md`를 갱신할 것.
```

### `CLAUDE.md` (Claude Code)
```markdown
# CLAUDE.md

이 프로젝트의 모든 컨텍스트는 [.harness/](./.harness/)에 있다.
작업 시작 전 `.harness/STATE.md` → `.harness/PLAN.md` 순서로 읽을 것.
큰 작업은 TodoWrite로 단계를 쪼개고, 완료마다 `.harness/STATE.md`를 갱신할 것.
```

### `.kiro/steering/project.md` (Kiro)
```markdown
---
inclusion: always
---

# Project Steering

이 프로젝트의 모든 컨텍스트는 [.harness/](../../.harness/)에 있다.
Spec 작성 전 `.harness/STATE.md`를 확인하고, Spec 완료 후 `.harness/MEMORY.md`에 결정 사항을 기록할 것.
```

## `.harness/` 내부 파일 포맷

### `ARCHITECTURE.md`
```markdown
# ARCHITECTURE

## 프로젝트 개요
{레포 한 줄 설명}

## 기술 스택
{언어/프레임워크/DB 등}

## 필요에 따라 머메이드로 시각화한 다이어그램, 파이프라인 등 추가

## 디렉토리 구조
{핵심 폴더만 간단히}

## 명령어
- 실행: `...`
- 테스트: `pytest` / `...`
- 린트: `ruff check .` / `...`

## 코딩 규칙
- [01-naming-rules.md](https://github.com/DPYB/.github/blob/main/docs/01-naming-rules.md)
- [02-git-conventions.md](https://github.com/DPYB/.github/blob/main/docs/02-git-conventions.md)
```

### `BACKLOG.md`
```markdown
# BACKLOG

## Now (이번 스프린트/세션 후보)
- {작업}

## Later
- {작업}

## 보류
- {작업}: {보류 이유}
```

### `PLAN.md`
```markdown
# PLAN

## 현재 목표
{한 문장}

## 단계
- [ ] {단계 1}
- [ ] {단계 2}

## 완료
- [x] {단계} (YYYY-MM-DD)
```

### `STATE.md`
```markdown
# STATE

## 지금 되는 것
- {항목}

## 지금 막혀있는 것 / 블로커
- {항목}: {이유}

## 마지막 업데이트
YYYY-MM-DD
```

### `MEMORY.md`
```markdown
# MEMORY

## 확정된 결정
- YYYY-MM-DD: {결정 내용, 이유}

## 재검토 필요
- {항목}: {이유}
```

## 운영 원칙

- `.harness/STATE.md`, `PLAN.md`는 PR 템플릿 체크리스트에 포함되어 있으므로 매 PR마다 갱신 여부를 확인한다.
- 툴을 바꿔서 이어받는 팀원은 `.harness/STATE.md` → `.harness/PLAN.md` → `.harness/ARCHITECTURE.md` 순서로 읽으면 컨텍스트를 따라잡을 수 있어야 한다.
- 레포별 세부 내용(`.harness/` 안의 실제 텍스트)은 이 핸드북이 아니라 **각 서비스 레포 안**에 위치한다 — 이 문서는 구조와 포맷만 표준화한다.
