# 04. 무과금(Zero-cost) 배포 정책

유료 서비스 종속성을 배제하고, 모든 서비스 레포(`backend-*`, `frontend-*`)는 아래 3단계 정책을 기본으로 따른다.

## 1단계 — 로컬 개발
- `docker-compose.yml` 기반, 볼륨 마운트로 핫리로드 (`uvicorn --reload` 등 프레임워크별 개발 서버).

## 2단계 — 무료 티어 우선 배포
- **호스팅**: Render Web Service (무료 Docker 호스팅)
- **DB**: Supabase (무료 PostgreSQL, 필요 시 스키마 격리로 MSA 분리)
- **DNS/CDN**: Cloudflare (무료 DNS, SSL, CDN)
- 정적 프론트엔드(`frontend-reader-web`)는 위 스택 대신 Vercel/Cloudflare Pages 등 정적 호스팅 무료 티어를 사용할 수 있다.

## 3단계 — GCP 무료 크레딧 폴백
- Render 무료 티어 한도(512MB RAM, 콜드스타트 지연 등)에 걸릴 경우에만 Google Cloud Run으로 전환.
- Cloud Run은 유휴 시 인스턴스 0개(Scale-to-Zero)로 크레딧 소비를 최소화한다.

## 공통 기술 요구사항
- **동적 포트 바인딩**: Dockerfile은 `$PORT` 환경변수를 바인딩해 Render와 Cloud Run 양쪽에서 코드 수정 없이 동일하게 동작하도록 유지한다.
- **DB 접속**: Supabase 커넥션 풀러(포트 6543) 사용 시, 서비스별로 필요하면 prepared statement 충돌 방지 설정을 확인한다 (예: asyncpg의 `statement_cache_size=0`).
- **CORS**: 프론트(Cloudflare)와 백엔드(Render)는 서로 다른 도메인이므로, 각 `backend-*` 레포는 프론트 도메인을 명시적으로 CORS 허용 목록에 등록한다.

## 무료 티어 슬립(Sleep) 이슈와 대응

무료 티어 조합(Cloudflare + Render + Supabase)은 두 지점에서 자동으로 슬립 상태에 들어간다.

| 서비스 | 슬립 조건 | 재시작(콜드 스타트) 시간 |
| :--- | :--- | :--- |
| Render (무료 웹서비스) | 15분 무활동 | 약 30~60초 |
| Supabase (무료 프로젝트) | 7일간 DB에 실제 쿼리 없음 (대시보드 방문은 포함 안 됨) | 약 30초 |

**대응**: GitHub Actions로 15분 간격 헬스체크 크론을 구성해 Render의 `/health` 엔드포인트를 호출하고, 그 엔드포인트가 내부적으로 Supabase에 가벼운 쿼리를 한 번 날리도록 만들면 두 슬립 문제를 하나의 크론으로 동시에 방지할 수 있다.

## 레포별 세부 사항
이 문서는 조직 공통 배포 원칙만 정의한다. 레포마다 실제로 어느 단계에 있는지, 구체적인 스키마/설정값은 각 레포 `.harness/ARCHITECTURE.md`에 기록한다.
