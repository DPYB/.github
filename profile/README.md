# 📚 DPYB — Don't Paw-get Your Book

> **"책을 읽고 흘려보내는 순간들을, 잊지 않도록."**  
> DPYB는 독서 중 남긴 문장과 메모를 개인화된 AI 사서와 함께 다시 꺼내볼 수 있는 지능형 독서 기록 플랫폼입니다.

---

## 🏛️ 레포지토리 & 아키텍처

DPYB는 **무과금(Zero-Cost) 클라우드 인프라**와 **독립 경량 MSA(Microservices Architecture)**를 지향하며, 서비스 목적에 맞게 분리된 레포지토리로 구성되어 있습니다.

| 레포지토리 | 역할 | 기술 스택 | 배포/인프라 |
| :--- | :--- | :--- | :--- |
| [**`frontend-reader-web`**](https://github.com/DPYB/frontend-reader-web) | 독자용 웹 애플리케이션 (3D 인터랙티브 서재 & 사서 대화) | React 19, Vite, Three.js (R3F), JavaScript → TypeScript 점진적 마이그레이션 | Cloudflare Pages / Vercel |
| [**`backend-core-api`**](https://github.com/DPYB/backend-core-api) | 소셜 로그인 인증(Google·Kakao, JWT) & 핵심 비즈니스 로직 (도서·서재·독서기록 RDBMS 단일 진실 공급원) | Python 3.12, FastAPI, SQLAlchemy, Alembic | Render Web Service + Supabase PostgreSQL |
| [**`backend-ai-agent`**](https://github.com/DPYB/backend-ai-agent) | AI 사서 & 개인화 RAG (ISBN 바코드 인식, 문장 스크랩 OCR, 대화형 메모 탐색) | Python 3.12, FastAPI, LangGraph, Supabase pgvector | Render Web Service |
| [**`.github`**](https://github.com/DPYB/.github) | 조직 공통 개발 핸드북, 재사용 CI/CD, 중앙 킵얼라이브 크론, 브랜치 보호 스크립트 | GitHub Actions, Shell Script | GitHub |

---

## 💡 엔지니어링 하이라이트

### 1. 💸 무과금(Zero-Cost) 고가용성 아키텍처
* **Zero-Cost 클라우드 조합**: Render(컨테이너 호스팅) + Supabase(PostgreSQL & pgvector) + Cloudflare(DNS/SSL/CDN) 무료 티어 적극 활용.
* **Keep-Alive 중앙 자동화**: GitHub Actions 스케줄 크론(`keep-alive.yml`)이 10분 주기로 백엔드 헬스체크(`/health`)를 수행하여 Render의 15분 유휴 슬립 및 Supabase의 7일 비활성화를 중앙에서 자동 방지합니다.
* **로컬 완결성 우선**: 모든 서비스는 `docker-compose` 기반으로 외부 클라우드 의존 없이 로컬에서 완전한 E2E 구동과 독립 테스트(`pytest`)가 가능하도록 설계되었습니다.

### 2. 🤖 바이브 코딩 하네스 (AI Harness)
* **Multi-Agent 호환성**: 팀원 및 환경에 따라 Codex, Claude Code, Antigravity, Kiro 등 다양한 AI 도구를 자유롭게 전환해 작업할 수 있도록 표준 하네스 체계를 구축했습니다.
* **단일 소유권 문서 체계**: 각 레포 내 `.harness/` 디렉토리를 통해 컨텍스트 충돌 없이 단일 진실을 유지합니다 (`HANDOFF`, `STATE`, `ARCHITECTURE`, `PLAN`, `DECISIONS`, `BACKLOG`).

### 3. 🛡️ 중앙화된 품질 & 거버넌스 자동화
* **재사용 CI & PR 린터**: `.github` 저장소에서 Python 3.12 린트/타입체크/테스트(`reusable-python-ci.yml`) 및 PR/커밋 컨벤션 검증(`reusable-pr-lint.yml`)을 원격 호출하여 관리 비용을 최소화합니다.
* **엄격한 PR 템플릿 (Type B)**: 목적, 변경 범위, AI 바이브 코딩 고려사항 & 리뷰 포인트, 체크리스트가 누락되지 않도록 CI에서 자동 검증합니다.
* **Human-in-the-Loop 원칙**: 에이전트는 계획, 코드 작성, 테스트, 커밋, PR 생성까지만 수행하며, `develop` 및 `main` 브랜치로의 최종 머지는 반드시 사람이 직접 리뷰 후 결정합니다.

### 4. 🎨 프론트엔드 점진적 모더나이제이션 (Front-end Evolution)
* **초기 프로토타이핑 가속**: 빠른 3D 가상 서재(Three.js/R3F) 인터랙션과 기능 구현을 위해 **React 19 + Vite** 기반의 JavaScript/JSX 환경으로 기틀을 다졌습니다.
* **단계별 마이그레이션 로드맵**:
  1. **JavaScript → TypeScript 전환**: 백엔드 API 계약(Contract) 및 핵심 데이터 모델(`Book`, `Scrap`, `LibrarianState`)부터 점진적으로 엄격한 타입 정의 적용.
  2. **서버 상태 관리 도입 (TanStack Query)**: 복잡한 Context API 내 수동 페칭/캐싱 로직을 서버 상태 전문 라이브러리로 분리하여 안정적인 비동기 통신과 캐시 무효화 확보.
  3. **디자인 시스템 및 스타일 현대화 (Tailwind CSS v4 / Vanilla Extract)**: 전역 CSS 분산 관리를 현대적인 유틸리티 클래스 또는 타입 안전 스타일링으로 정돈하여 일관된 큐레이션 서재 UI 테마 구축.
  4. **PWA & 오프라인 캐싱 (Vite PWA)**: 무과금 정적 호스팅(Cloudflare Pages)의 이점을 극대화하면서 네이티브 앱과 같은 모바일 독서/스크랩 UX 제공.

---

## 📖 개발 핸드북 & 가이드라인

DPYB 조직의 상세한 엔지니어링 표준은 [`.github`](https://github.com/DPYB/.github) 저장소의 핸드북 문서에서 확인하실 수 있습니다:

1. 🏷️ [**네이밍 규칙**](https://github.com/DPYB/.github/blob/main/docs/01-naming-rules.md) — 서비스/브랜치/코드 네이밍 표준
2. 🔀 [**Git 컨벤션**](https://github.com/DPYB/.github/blob/main/docs/02-git-conventions.md) — 브랜치 전략, Conventional Commits, PR 템플릿
3. 🦾 [**바이브 코딩 하네스**](https://github.com/DPYB/.github/blob/main/docs/03-vibe-coding-harness.md) — AI 에이전트 협업 및 컨텍스트 관리 표준
4. 🚀 [**무과금 배포 정책**](https://github.com/DPYB/.github/blob/main/docs/04-deployment-policy.md) — 로컬 개발 우선, 무료 티어 배포 및 슬립 대응 정책

