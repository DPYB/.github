# 02. Git 컨벤션

## 브랜치 전략 (경량 Git Flow)

소규모 팀 + 무과금 배포 특성을 고려해 무거운 Git Flow 대신 **Trunk-based에 가까운 경량 버전**을 사용한다.
ㄴ 음 나는 이게 더 어려운것 같은데.. 차라리 develop브랜치 두고 거기에 pr하는게 좋지 않을까? 지라 같은걸 사용하지 않아서 티켓번호를 어떻게 해야할지 모르겠지만 전 서비스에서도 그렇게 사용하기도 했고 그리고 국문 사용했으면 좋겠어

```
main            # 항상 배포 가능한 상태 (프로덕션)
 └─ feature/*   # 신규 기능
 └─ fix/*       # 버그 수정
 └─ chore/*     # 빌드/설정/문서 등 비기능 변경
 └─ refactor/*  # 동작 변경 없는 코드 개선
```

- `develop` 브랜치는 별도로 두지 않는다 — PR은 곧바로 `main`을 대상으로 연다.
- `main`에 직접 push 금지, 반드시 PR + 리뷰(또는 self-review)를 거친다.
- 배포는 `main`에 머지되는 시점에 자동 트리거되는 것을 기본으로 한다 (레포별 CI/CD 문서 참고).

## 커밋 메시지 — Conventional Commits

```
<type>(<scope>): <description>

[optional body]
[optional footer]
```

### type 목록
| type | 설명 |
|---|---|
| `feat` | 새로운 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변경 없는 코드 구조 개선 |
| `chore` | 빌드, 설정, 의존성, 문서 등 |
| `test` | 테스트 추가/수정 |
| `docs` | 문서만 변경 |
| `perf` | 성능 개선 |

### scope 예시
서비스/도메인 단위로 작성한다: `agent`, `rag`, `persona`, `auth`, `bookshelf` 등

### 예시
```
feat(persona): add handoff summarizer node

기존 대화 톤을 제거하고 팩트만 다음 페르소나에게 전달하는
summarizer_node를 LangGraph 워크플로우에 추가.

Closes #12
```

## PR 규칙

- 제목도 커밋 메시지와 동일한 `type(scope): description` 형식을 따른다.
- 1 PR = 1 목적을 기본 원칙으로 하되, AI 에이전트로 큰 단위 작업을 한 경우 PR 설명에 `PLAN.md` 요약을 포함한다 ([03-vibe-coding-harness.md](./03-vibe-coding-harness.md) 참고).
- 리뷰어가 없는 개인 작업이어도 PR 템플릿의 체크리스트는 생략하지 않는다.
