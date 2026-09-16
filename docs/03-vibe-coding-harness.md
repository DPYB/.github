# 03. 바이브 코딩 하네스

팀원마다 사용하는 AI 코딩 툴이 다르기 때문에(Codex, Claude Code, Antigravity(AGY), Kiro), **어떤 툴로 세션을 열어도 동일한 컨텍스트와 워크플로우로 이어받을 수 있도록** 모든 서비스 레포(`backend-*`, `frontend-*`)가 아래 구조를 공통으로 가져간다.

> ⚠️ 이 표준은 `.github` 레포 안에 있을 뿐 GitHub이 자동으로 각 서비스 레포에 적용해주는 건 아니다. 새 레포를 만들 때 아래 템플릿을 직접 복사해서 반영해야 한다.

```
{repo-root}/
├── AGENTS.md              # 실질적 규칙집 — 읽기 순서, 문서 소유권, 워크플로우 사이클 (Codex, Antigravity 공용)
├── CLAUDE.md               # Claude Code용 — "AGENTS.md를 따르라"는 얇은 어댑터
├── .kiro/
│   └── steering/
│       └── project.md      # Kiro용 — "AGENTS.md를 따르라"는 얇은 어댑터
├── .githooks/
│   └── pre-commit          # 커밋 시 STATE.md 갱신 환기 (초경량 비차단 경고)
├── .agyignore              # 에이전트 시야 차단 (docs/archive/**, build/, fixtures 등)
└── .harness/
    ├── HANDOFF.md           # 세션별 서술형 로그 (3-Strike Out 시 실패 원인 영속화)
    ├── STATE.md             # 완료된 마일스톤 단계 요약 스냅샷
    ├── ARCHITECTURE.md      # 지금 시점의 기술 스택/구조/컨벤션 (현재 상태)
    ├── PLAN.md              # 아직 안 끝난 계획 + 체크리스트만 (What)
    ├── DECISIONS.md         # 중요 결정과 이유 (Why, append-only, 최신이 최상단)
    ├── BACKLOG.md           # 미해결 항목, 기술부채, 이월된 미완료 태스크
    └── sessions/            # (선택) 대규모 기능 브랜치 작업 격리 및 자동 청소
```

---

## 왜 문서 하나가 아니라 6개로 쪼개는가

문서 하나에 모든 걸 적으면 "이 내용을 어디에 적어야 하나"를 매번 판단해야 하고, 결국 같은 정보가 여러 곳에 중복/불일치하게 된다. 문서마다 **단일 소유권**을 강제하면 이 문제가 사라진다.

| 문서 | 담는 내용 (단일 소유) | 담지 않는 내용 |
| :--- | :--- | :--- |
| `HANDOFF.md` | 세션마다 무엇을 했는지 서술형 로그 (append-only, 3-Strike 실패 시 인계 기록) | 단계별 완료 요약(STATE 몫), 결정 이유(DECISIONS 몫) |
| `STATE.md` | 지금까지 끝난 기능의 마크로 마일스톤 한 줄 요약 스냅샷 | 세션별 서술(HANDOFF 몫). 이슈 하나하나를 로그처럼 쌓지 않는다 |
| `ARCHITECTURE.md` | 현재 시점의 기술 스택, 폴더 구조, 코딩 컨벤션 (현재 상태) | 왜 그렇게 정했는지(DECISIONS 몫), 진행 중인 계획(PLAN 몫) |
| `DECISIONS.md` | 중요한 아키텍처/기술적 결정 내용과 그 이유 (Why, append-only) | 구현 여부나 진행 상황(STATE 몫) |
| `PLAN.md` | 아직 안 끝난 계획과 체크리스트만 (What) | 완료된 항목 (체크만 남기지 말고 STATE로 옮긴 뒤 제거) |
| `BACKLOG.md` | 지금 하지 않지만 나중에 할 기술부채, 버그, 이월된 작업 풀 | 현재 진행 중인 계획(PLAN 몫) |

---

## 작업 워크플로우 (필수 표준)

1. **세션 시작 시 고아 폴더 지연 청소 (Lazy Cleanup)**:
   - **작업 착수 전, `.harness/sessions/` 하위에 잔여 폴더가 있는지 먼저 확인**하고 있다면 미완료 항목을 `BACKLOG.md`로 우선 이관·정리한 뒤 본작업에 들어간다.
2. **컨텍스트 로딩 및 패스트트랙**:
   - **단순 버그/오탈자**: `.harness/STATE.md`와 `ARCHITECTURE.md`만 읽고 즉시 수정한다 (세션 폴더 생략).
   - **신규 기능/구조 변경**: 위 문서와 함께 `.harness/DECISIONS.md`를 필독한다.
   - **Fail-safe 원칙**: 패스트트랙 적용 여부가 조금이라도 애매한 경우 기본값은 무조건 **'정식 워크플로우(계획 수립 후 승인)'**로 진행한다.
3. **계획 수립 및 사용자 승인**:
   - 새로운 기능/변경 요청을 받으면 바로 코드를 고치지 말고 `.harness/PLAN.md`(대규모 작업 시 `.harness/sessions/{branch}/PLAN.md`)에 계획 초안을 작성해 사용자에게 제시한다.
   - 사용자가 명시적으로 컨펌하면 구현을 시작한다. 구현 방식(TDD 등)은 레포 특성에 맞는 개발 사이클을 따르되, "확인 → 구현 → 기록"의 순서 자체는 모든 레포 공통으로 강제한다.
4. **점진적 반영 및 자가 정돈 (Pre-PR Wrap-up)**:
   - `PLAN.md`의 세부 체크리스트가 완료될 때마다 즉시 `.harness/STATE.md`에 한 줄로 반영하고 `PLAN.md`에서 제거한다.
   - 브랜치 작업 완료 시, PR을 요청하기 전 `PLAN.md`의 미완료 항목은 루트 `BACKLOG.md`로 이관하고, `.harness/sessions/{branch}/` 디렉토리를 스스로 삭제한 뒤 최종 커밋을 생성한다.
5. **자가 검증 2단계 파이프라인 (3-Strike Out 과열 방지)**:
   - **누적 원칙**: 모든 Strike 카운트는 **단일 작업(세션) 누적 기준**이며, 새로운 에러가 발생하거나 에러 종류가 바뀌어도 리셋되지 않는다.
   - **Step 0 (자동 수정)**: `ruff --fix`, `prettier` 등 도구 기반 자동 수정은 세션 통틀어 **최대 5회**까지 허용 (초과 시 린터 충돌로 간주하고 Step 1로 격상).
   - **Step 1 (추론 수정)**: 테스트 실패, 비즈니스 로직 에러 등 추론 기반 수정은 세션 통틀어 **최대 3회**까지만 재시도. 3회 실패 시 즉시 루프를 멈추고 `HANDOFF.md`에 시도 내역을 요약한 뒤 사람에게 개입을 요청한다.
6. **시야 차단 추적**:
   - 표준 빌드/로그 경로(build, dist, logs, fixtures, node_modules, `docs/archive/**`)는 승인 없이 `.agyignore`에 추가한다.
   - 그 외 실제 소스/설정 파일 배제 시에는 반드시 "무시한 파일명과 사유"를 사용자에게 1줄 보고 후 승인을 받는다.
7. **출력 다이어트 & 역할 분리 (What vs Why)**:
   - 인사말, 서론, 결론을 일체 생략하고 작업 결과 코드와 핵심 질의만 출력한다.
   - `PLAN.md`는 할 일(What)만 체크리스트로 작성하고, 기술 결정의 이유(Why)는 반드시 `DECISIONS.md`에 누적하여 2주 뒤 복귀 시의 컨텍스트 스위칭 비용을 방어한다.
8. **커밋 및 PR 생성 규격**:
   - 커밋은 사용자가 명시적으로 요청했을 때만 수행하며, 변경된 파일만 선별해 스테이징한다 (`git add .` 지양).
   - PR 본문은 조직 공통 템플릿(`.github/pull_request_template.md`)의 Type B 규격을 100% 준수하여 작성한다:
     1. `## 🎯 작업 요약`: 목적과 주요 변경사항 명확화.
     2. `## 🌐 적용 범위`: 영향받는 API/도메인/컴포넌트 명시.
     3. `## 💬 고려사항 & 리뷰 포인트`: 설계 트레이드오프, 잠재적 부작용 기술.
     4. `## ✅ 체크리스트`: 작업 완료 항목 체크.
   - **인간 개입 및 머지 권한**: `develop` 및 `main` 브랜치로의 **최종 PR 머지 버튼은 에이전트가 자율 실행하지 않고 사람이 직접 검토 후 누른다**.

---

## `AGENTS.md` 템플릿 (레포 루트, 실질적 규칙집)

레포별로 기술 스택이 다르므로 아래 뼈대에서 스택 관련 세부 정책만 채워 넣는다. 브랜치/커밋/배포 정책은 조직 표준([02-git-conventions.md](./02-git-conventions.md), [04-deployment-policy.md](./04-deployment-policy.md))을 그대로 링크하고 여기 다시 적지 않는다.

```markdown
# AGENTS.md — 개발 하네스 지침

## 1. 세션 시작 시 필수 실행 순서
어떤 AI 도구(Claude Code, Codex, Antigravity, Kiro 등)로 세션을 시작하든 아래 순서대로 먼저 착수한다:
1. `.harness/sessions/` 확인 — 잔여 세션 폴더가 있다면 미완료 항목을 `BACKLOG.md`로 이관 후 삭제 (지연 청소).
2. `.harness/HANDOFF.md` — 직전 세션이 어디서 멈췄는지 (3-Strike 실패 인계 확인).
3. `.harness/STATE.md` — 지금까지 무엇이 완료되었는지.
4. `.harness/ARCHITECTURE.md` — 기술 스택/폴더 구조/컨벤션.
5. 작업 크기에 따라 분기:
   - 단순 버그/오탈자: 즉시 수정 착수. (애매하면 6번 정식 워크플로우 준수)
   - 신규 기능/구조 변경: `.harness/DECISIONS.md` 필독 후 `PLAN.md` 초안 작성.

## 2. 문서별 책임 (중복 기록 금지)

| 문서 | 담는 내용 | 담지 않는 내용 |
| :--- | :--- | :--- |
| `HANDOFF.md` | 세션마다 무엇을 했는지 서술형 로그 (append-only, 실패 인계) | 단계별 완료 요약(STATE 몫), 결정 이유(DECISIONS 몫) |
| `STATE.md` | 지금까지 끝난 것의 마크로 마일스톤 요약 스냅샷 | 세션별 서술(HANDOFF 몫) |
| `ARCHITECTURE.md` | 지금의 기술 스택/폴더 구조/컨벤션 (현재 상태) | 왜 그렇게 정했는지(DECISIONS 몫), 진행 상황(STATE 몫) |
| `DECISIONS.md` | 결정 내용과 이유의 역사 (최신 결정이 맨 위로, append-only) | 구현 여부/진행 상황(STATE 몫) |
| `PLAN.md` | 아직 안 끝난 계획과 체크리스트만 (What) | 완료된 항목 (STATE로 옮긴 뒤 제거) |
| `BACKLOG.md` | 지금 하지 않지만 나중에 할 것, 이월된 미완료 태스크 풀 | 진행 중인 계획(PLAN 몫) |

## 3. 작업 워크플로우 (필수 준수)

- **계획 수립 우선 & 패스트트랙**: 신규 기능/변경 요청은 `PLAN.md`에 계획 초안을 작성해 컨펌 후 구현한다. 단순 오탈자는 계획 없이 즉시 수정하되, 애매하면 계획 수립이 기본값이다.
- **자가 검증 3-Strike Out (누적 카운트)**:
  - Step 0 (자동 수정): `ruff --fix`, `prettier` 등 도구 수정은 세션 누적 최대 5회.
  - Step 1 (추론 수정): 비즈니스 로직/테스트 에러는 세션 누적 최대 3회. 3회 실패 시 `HANDOFF.md`에 기록하고 사용자에게 개입 요청.
- **Pre-PR 자가 정돈**: 브랜치 작업 완료 시, `PLAN.md` 미완료 태스크를 `BACKLOG.md`로 옮기고 `.harness/sessions/`를 스스로 삭제한 뒤 커밋한다.
- **출력 간소화**: 사족(인사말, 서론, 결론) 없이 결과 코드와 질문만 출력한다.
- **인간 최종 승인**: 최종 PR 머지는 사람이 직접 검토 후 수행한다.

## 4. 이 레포 고유 정책
{DB, 테스트, 배포 등 이 레포만의 정책 — 상세 내용은 `.harness/ARCHITECTURE.md`를 참고}

## 5. 브랜치 & 커밋 컨벤션
[DPYB `.github` 레포의 02-git-conventions.md](https://github.com/DPYB/.github/blob/main/docs/02-git-conventions.md)를 따른다.

## 6. 배포
[DPYB `.github` 레포의 04-deployment-policy.md](https://github.com/DPYB/.github/blob/main/docs/04-deployment-policy.md)를 따른다.
```

---

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

---

## 동료 협업 최소 안전망 (.githooks 설정)

동료가 `STATE.md` 갱신을 누락하는 것을 방지하기 위해 Git 추적 경로(`.githooks/pre-commit`)를 활용한다 (클라우드 CI 관리 부담 0).

### 1. 스택별 활성화 방법 (최초 1회)
* **프론트엔드 (`frontend-reader-web`)**: `package.json`의 `"scripts"`에 아래 항목을 추가하여 `npm install` 시 자동 활성화:
  ```json
  "prepare": "git config core.hooksPath .githooks || true"
  ```
* **백엔드 (`backend-*`)**: 레포 클론 후 터미널에서 최초 1회 수동 실행:
  ```bash
  git config core.hooksPath .githooks && chmod +x .githooks/pre-commit
  ```

### 2. `.githooks/pre-commit` 스크립트 내용 (POSIX 호환)
```bash
#!/bin/sh
# 소스 코드가 수정되었는데 STATE.md가 스테이징에 없으면 터미널에 경고 출력 (Non-blocking)
CHANGED_CODE=$(git diff --cached --name-only | grep -E '\.(ts|tsx|py|go|java|js)$' || true)
STATE_MODIFIED=$(git diff --cached --name-only | grep 'STATE\.md$' || true)

if [ -n "$CHANGED_CODE" ] && [ -z "$STATE_MODIFIED" ]; then
  printf "\033[33m⚠️ [Harness Notice] 소스 코드 변경이 감지되었으나 .harness/STATE.md가 수정되지 않았습니다.\033[0m\n"
  printf "\033[33m   완료된 주요 마일스톤이 있다면 STATE.md를 함께 갱신해주세요.\033[0m\n"
fi
exit 0
```

---

## `.harness/` 초기 템플릿

### `HANDOFF.md`
```markdown
# HANDOFF (세션별 서술 로그, append-only)

## YYYY-MM-DD: 프로젝트 초기 세팅
- {이번 세션에서 한 일}

**다음 세션 시작 시**: {다음에 확인/진행할 것}

---
<!-- 3-Strike Out 발생 시 아래 형식으로 인계 기록 -->
## YYYY-MM-DD: [3-Strike Out] {실패한 작업명}
- **접근 1**: {시도 내용 및 실패 원인}
- **접근 2**: {시도 내용 및 실패 원인}
- **접근 3**: {시도 내용 및 실패 원인}
- **사수 개입 요청 포인트**: {막힌 지점 및 확인 필요 사항}
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
# PLAN (미완료 계획, What)

완료된 항목은 여기 체크만 남기지 않고 `STATE.md`로 옮긴 뒤 이 문서에서 제거한다.

## {진행 중인 작업명}
- [ ] {단계 1}
- [ ] {단계 2}
```

### `DECISIONS.md`
```markdown
# DECISIONS (결정 히스토리, Why, 최신 결정이 최상단)

결정 내용과 이유만 기록한다. 진행 상황은 `STATE.md`를 본다.

| 날짜 | 결정 | 이유 / 대안 비교 |
| :--- | :--- | :--- |
| YYYY-MM-DD | {결정} | {이유} |
```

### `BACKLOG.md`
```markdown
# BACKLOG (미해결 항목 및 기술 부채)

지금 하지 않지만 나중에 할 것, 세션 종료 시 이월된 태스크들을 기록한다. 진행 중인 계획은 `PLAN.md`에 둔다.

- [ ] {항목}
```

---

## 새 레포에 적용하는 방법

1. 레포 루트에 `AGENTS.md` 생성 (위 템플릿에서 "이 레포 고유 정책"만 채움).
2. `CLAUDE.md`, `.kiro/steering/project.md` 얇은 어댑터 생성.
3. `.harness/` 폴더에 6개 초기 템플릿 생성.
4. `.githooks/pre-commit` 생성 및 훅 활성화 실행.
5. AI 에이전트에게 첫 명령: **"`AGENTS.md`의 하네스 지침을 읽고, `.harness/PLAN.md`의 첫 번째 체크리스트부터 구현 계획을 세워줘."**

---

## 운영 원칙

- `.harness/STATE.md`, `PLAN.md`, `HANDOFF.md`는 PR 템플릿 체크리스트에 포함되어 있으므로 매 PR마다 갱신 여부를 확인한다.
- 툴을 바꿔서 이어받는 팀원은 `AGENTS.md`의 읽기 순서(`sessions/` 지연 청소 → `HANDOFF` → `STATE` → `ARCHITECTURE` → `PLAN`)만 따라가면 컨텍스트를 따라잡을 수 있어야 한다.
- 레포별 세부 내용(`.harness/` 안의 실제 텍스트, `AGENTS.md`의 "이 레포 고유 정책")은 이 핸드북이 아니라 **각 서비스 레포 안**에 위치한다 — 이 문서는 구조·포맷·워크플로우만 표준화한다.
