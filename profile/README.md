# 📚 DPYB — Don't Paw-get Your Book

> **"책을 읽고 흘려보내는 순간들을, 잊지 않도록."**  
> DPYB는 Three.js 3D 가상 서재에 책을 꽂고, 4종 동물 사서 및 4인 전문 파트너와 실시간 대화·심층 토론을 나누며 날씨와 기분에 맞는 책을 추천받고 독서 기록을 시각화하는 지능형 독서 플랫폼입니다.

---

## 🏛️ 레포지토리 & 아키텍처

DPYB는 **무과금(Zero-Cost) 고가용성 클라우드 인프라**와 **독립 경량 MSA(Microservices Architecture)**를 지향하며, 서비스 목적에 맞게 분리된 레포지토리로 구성되어 있습니다.

| 레포지토리 | 역할 | 기술 스택 | 배포/인프라 |
| :--- | :--- | :--- | :--- |
| [**`frontend-reader-web`**](https://github.com/DPYB/frontend-reader-web) | 3D 가상 서재, 실시간 사서 대화 & 3단계 독서 토론, 하이브리드 도서 등록 & OCR, 다국어(한/영) 지원 독자용 웹 클라이언트 | React 19, Vite 8, Three.js (R3F), Recharts, jspdf, TypeScript 점진 마이그레이션 | Cloudflare Pages (정적 SPA 배포) |
| [**`backend-core-api`**](https://github.com/DPYB/backend-core-api) | 소셜/게스트 인증(JWT), 가상 서재 도서·책장(LexoRank), 초 단위 정밀 독서 타이머, 국립도서관·YES24 서지 연동 및 월간 정량 통계 집계 단일 진실 공급원(SSOT) | Python 3.12, FastAPI, SQLAlchemy 2.0 (asyncpg), Alembic, Pydantic v2 | Google Cloud Run (asia-northeast3 서울 리전) + Supabase PostgreSQL |
| [**`backend-ai-agent`**](https://github.com/DPYB/backend-ai-agent) | 2-Track 8개 페르소나(사서 4종 + 토론 4인) SSE 스트리밍, 환각 방지 실서지 검증 도서 큐레이터, Gemini Flash Vision 무상태 OCR 및 Supabase pgvector RAG | Python 3.12, FastAPI, LangGraph, Google Gemini (Flash Lite / Vision), pgvector | Google Cloud Run (asia-northeast3 서울 리전) + Upstash Serverless Redis |
| [**`.github`**](https://github.com/DPYB/.github) | 조직 공통 개발 핸드북, 재사용 CI/CD, 중앙 킵얼라이브 크론, 브랜치 보호 및 컨벤션 거버넌스 자동화 | GitHub Actions, Shell Script, Python | GitHub |

---

## 💡 엔지니어링 하이라이트

### 1. 💸 무과금(Zero-Cost) 고가용성 하이브리드 CaaS 아키텍처
* **서버리스 컨테이너(CaaS) & 오토스케일링**: 백엔드 서비스는 유휴 시 인스턴스가 0개로 축소(**Scale-to-Zero**)되어 비용을 최소화하는 **Google Cloud Run(서울 리전)**과 **Upstash Serverless Redis**를 주력으로 운용하며, Render 및 Supabase 무료 티어를 유연하게 결합했습니다.
* **Keep-Alive 중앙 자동화**: GitHub Actions 스케줄 크론(`keep-alive.yml`)을 통해 백엔드 헬스체크(`/health`)를 주기적으로 수행하여 무료 티어 DB 슬립을 중앙에서 방지합니다.
* **로컬 완결성 우선**: 모든 서비스는 `docker-compose` 기반으로 외부 클라우드 의존 없이 로컬에서 완전한 E2E 구동과 독립 테스트(`pytest`)가 가능하도록 설계되었습니다.

### 2. 🎭 2-Track 8개 페르소나 오케스트레이션 & 환각 방지 큐레이터
* **LangGraph 기반 어조 격리**: 사서 모드 4종(`블루`, `슈빌`, `누디`, `게코`)과 토론 모드 4종(`평론가`, `이야기꾼`, `상담사`, `관찰가`) 간 전환 시 어조 오염을 물리적으로 차단하는 `summarizer_node` 및 Redis 세션 네임스페이스 격리를 적용했습니다.
* **4단계 실서지 검증 도서 큐레이터**: LLM의 도서 환각(Hallucination)을 원천 차단하기 위해 **국립중앙도서관 정식 서지 API**와 교차 검증하여 13자리 ISBN, 교보문고 고화질 CDN 표지, 실제 쪽수, 정식 출판사가 보증된 실존 도서만 프론트엔드 등록 카드로 바인딩합니다.
* **무상태 Vision & OCR**: Gemini Flash Vision을 통해 책 표지 바코드(ISBN-13) 및 문장 수집 크롭 이미지 텍스트를 줄바꿈 손상 없이 정밀 추출합니다.

### 3. 🎨 반응형 3D 가상 서재 & 글로벌 UX
* **사서별 3D 서재 캘리브레이션**: Three.js/R3F 기반 서재에 책을 꽂을 때, 사서별 고유 시야각(FOV 28도 보정)과 마우스 추적 커서, 손전등 효과를 지원합니다.
* **모바일/태블릿 터치 통합 UX**: 768px 이하 디바이스에서는 선반 선택 오버레이 및 상하 수직 스크롤 바텀시트(`MobileShelfSheet`), 드래그형 플로팅 사서 버튼(`MobileChatFAB`)을 제공합니다.
* **전역 다국어 지원 & 온보딩 가이드**: 한국어/영어 원클릭 스위칭(`i18n`)과 서비스 초기 진입 사용 가이드 모달을 통해 글로벌 접근성을 확보했습니다.
* **데이터 시각화 & PDF 내보내기**: Recharts 기반 주간 독서 흐름 및 KDC 10대 장르 점유율 차트, 사서 맞춤형 원클릭 PDF 다운로드(`html2canvas` + `jspdf`)를 지원합니다.

### 4. 🔐 심사/시연 안전성: 무결점 게스트 모드 & 멱등 데모 리셋
* **[DPYB 체험하기] 원클릭 게스트 모드**: 별도 가입 절차 없이 즉시 가상 서재를 둘러볼 수 있도록 전용 게스트 JWT(`POST /api/v1/auth/guest`)를 발급하며, 악의적 데이터 변조를 차단하는 **무결점 Read-Only 락(모든 쓰기 403 Forbidden)** 미들웨어를 구축했습니다.
* **데모 시드 SSOT & 멱등 리셋 크론**: 공식 데모 계정의 시연 데이터를 멱등 복원하는 관리자 API(`POST /api/v1/admin/demo/reset`)와 GitHub Actions 일일 자동 청소 워크플로우를 운용합니다.

### 5. 🤖 바이브 코딩 하네스 & 계층형 자가 검증 (Tiered Verification)
* **단일 소유권 문서 체계**: 각 레포 내 `.harness/` 디렉토리를 통해 컨텍스트 충돌 없이 단일 진실을 유지합니다 (`HANDOFF`, `STATE`, `ARCHITECTURE`, `PLAN`, `DECISIONS`, `BACKLOG`).
* **3단계 계층형 자가 검증 체계**:
  - **Tier 1 (작업 중 초고속 루프)**: 하네스 규격 검사(`check_harness`) 및 린트(0.2초대 피드백).
  - **Tier 2 (커밋 직전 로컬 검증)**: 타입체크(`mypy` / `tsc`) 및 핵심 단위 회귀 테스트.
  - **Tier 3 (원격 CI 안전망)**: GitHub Actions 중앙 CI(`reusable-python-ci.yml`, `reusable-pr-lint.yml`) 전수 검사.
* **Human-in-the-Loop 원칙**: 에이전트는 기획, 코드 작성, 테스트, 커밋, PR 생성까지만 수행하며, `develop` 및 `main` 브랜치로의 최종 머지는 사람이 직접 리뷰 후 클릭합니다.

---

## 📖 개발 핸드북 & 가이드라인

DPYB 조직의 상세한 엔지니어링 표준은 [`.github`](https://github.com/DPYB/.github) 저장소의 핸드북 문서에서 확인하실 수 있습니다:

1. 🏷️ [**네이밍 규칙**](https://github.com/DPYB/.github/blob/main/docs/01-naming-rules.md) — 서비스/브랜치/코드 네이밍 표준
2. 🔀 [**Git 컨벤션**](https://github.com/DPYB/.github/blob/main/docs/02-git-conventions.md) — 브랜치 전략(`feat/*`), Conventional Commits, Type B PR 템플릿
3. 🦾 [**바이브 코딩 하네스**](https://github.com/DPYB/.github/blob/main/docs/03-vibe-coding-harness.md) — AI 에이전트 협업 및 컨텍스트 관리 표준
4. 🚀 [**무과금 배포 정책**](https://github.com/DPYB/.github/blob/main/docs/04-deployment-policy.md) — 로컬 개발 우선, 무료 티어 배포 및 슬립 대응 정책
5. ☁️ [**클라우드 마이그레이션 가이드**](https://github.com/DPYB/.github/blob/main/docs/05-cloud-migration-guide.md) — Google Cloud Run CaaS 전환 및 CI/CD 배포 자동화
