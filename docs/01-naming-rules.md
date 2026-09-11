# 01. 네이밍 규칙

## 레포지토리 이름

`{역할}-{서비스명}` 형태의 **kebab-case**를 사용한다.

| 역할 | 접두사 | 예시 |
|---|---|---|
| 백엔드 서비스 | `backend-` | `backend-auth-api`, `backend-core-api`, `backend-ai-agent` |
| 프론트엔드 | `frontend-` | `frontend-reader-web` |
| 조직 공용 | (접두사 없음) | `.github` |

### 확정된 DPYB 레포 목록
- frontend
  - `frontend-reader-web`
- backend
  - `backend-auth-api`
  - `backend-core-api`
  - `backend-record-api`
  - `backend-ai-agent`

## 브랜치 이름

`{type}/{한글-설명}` 형태. `type`은 [02-git-conventions.md](./02-git-conventions.md)의 커밋 타입과 동일한 세트를 사용하고, 지라 같은 티켓 관리 도구를 쓰지 않으므로 설명 부분은 한글로 작성한다.

```
feature/페르소나-핸드오프-그래프
fix/스크랩벡터-널체크
chore/pr템플릿-정리
```

## 코드 내부 네이밍 (언어별)

### Python (`backend-*`)
| 대상 | 컨벤션 | 예시 |
|---|---|---|
| 변수, 함수 | `snake_case` | `search_scrap_memory()` |
| 클래스 | `PascalCase` | `PersonaHandoffState` |
| 상수 | `UPPER_SNAKE_CASE` | `MAX_SCRAP_RESULTS` |
| 모듈/파일명 | `snake_case.py` | `rag_tool.py` |

- 나머지 서버 레포는 전부 python + fast api

### TypeScript / React (`frontend-reader-web`)
| 대상 | 컨벤션 | 예시 |
|---|---|---|
| 변수, 함수 | `camelCase` | `fetchScrapList()` |
| 컴포넌트, 타입, 인터페이스 | `PascalCase` | `BookshelfCard`, `ScrapItem` |
| 상수 | `UPPER_SNAKE_CASE` | `MAX_UPLOAD_SIZE` |
| 컴포넌트 파일명 | `PascalCase.tsx` | `BookshelfCard.tsx` |
| 훅 파일명 | `useCamelCase.ts` | `useScrapList.ts` |

- 프론트 아직 안정함 react, vite는 확정 아마 next.js쓸것 같음 

## 환경 변수

모든 레포 공통으로 `UPPER_SNAKE_CASE`, 서비스 접두사를 붙인다.

```
AI_AGENT_GEMINI_API_KEY=
CORE_API_DATABASE_URL=
```
