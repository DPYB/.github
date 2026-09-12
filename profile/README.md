# 📚 DPYB — Don't Paw-get Your Book

책을 읽고 흘려보내는 순간들을, 잊지 않도록.

DPYB는 독서 중 남긴 문장과 메모를 개인화된 AI 사서와 함께 다시 꺼내볼 수 있는 독서 기록 플랫폼입니다.
무과금(Zero-cost) 아키텍처를 지향하며, 경량 MSA 구조로 개발하고 있습니다.

## 🏛️ 레포지토리 구성

| 레포 | 역할 |
|---|---|
| [`frontend-reader-web`](https://github.com/DPYB/frontend-reader-web) | 독자용 웹 & PWA |
| [`backend-auth-api`](https://github.com/DPYB/backend-auth-api) | 인증/인가 (로그인, JWT) |
| [`backend-core-api`](https://github.com/DPYB/backend-core-api) | 핵심 비즈니스 로직 (회원, 책장, 스크랩 등 RDBMS CRUD) |
| [`backend-record-api`](https://github.com/DPYB/backend-record-api) | {용도 확인 필요} |
| [`backend-ai-agent`](https://github.com/DPYB/backend-ai-agent) | AI 사서 & 개인화 RAG (LangGraph, Supabase pgvector) |

모든 백엔드 레포는 Python + FastAPI로 통일되어 있습니다.

## 🛠️ 개발 규칙

조직 전체 개발 규칙(네이밍, Git 컨벤션, AI 바이브 코딩 하네스, 배포 정책)은 이 레포([`.github`](https://github.com/DPYB/.github))의 [핸드북](../README.md)에서 관리합니다.
