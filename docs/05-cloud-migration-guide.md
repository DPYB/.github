# 05. 클라우드 마이그레이션 가이드 (GCP / AWS 전환 및 배포 자동화)

> Render 무료 티어(0.1 vCPU, 512MB RAM, 15분 슬립) 한계로 인해 컴퓨팅 성능 저하나 응답 지연(콜드 스타트, LLM/비전 추론 지연)이 발생할 경우, **GCP Cloud Run(1순위)** 또는 **AWS App Runner / ECS(2순위)**로 신속하게 전환하기 위한 공식 아키텍처 및 CI/CD 구축 가이드입니다.

---

## 1. 전환 판단 기준 (Trigger Conditions)

DPYB 서비스(`backend-core-api`, `backend-ai-agent`)는 모두 **Python 3.12 + FastAPI + Dockerfile** 기반으로 컨테이너화되어 있습니다. 아래 상황 발생 시 클라우드 마이그레이션을 즉시 실행합니다:

| 증상 | 원인 | 조치 권장 |
| :--- | :--- | :--- |
| **채팅 응답 지연 (초기 응답 10초 이상)** | Render 무료 티어의 0.1 vCPU 스로틀링 및 512MB 메모리 스왑 | **GCP Cloud Run 전환 (최소 1~2 vCPU, 1~2GB RAM 할당)** |
| **첫 요청 타임아웃 (콜드 스타트)** | Render 15분 무활동 슬립 모드 해제 지연 (30~60초) | Cloud Run 최소 인스턴스 1개 설정 또는 빠른 컨테이너 기동 활용 |
| **비전/OCR 처리 중 컨테이너 크래시 (OOM)** | 바코드 이미지 디코딩(`pyzbar`) 및 대용량 I/O 메모리 초과 | 컨테이너 메모리 1GB 이상 증설 |

---

## 2. GCP Cloud Run 전환 가이드 (권장 1순위)

Google Cloud Run은 **Serverless Container(CaaS)** 플랫폼으로, 컨테이너가 유휴 상태일 때 인스턴스 0개로 축소(**Scale-to-Zero**)되어 비용을 최소화(또는 신규 가입 $300 무료 크레딧 소비)하면서도, 요청 시 최대 수 vCPU / 수 GB RAM까지 신속하게 확장할 수 있습니다.

### 2.1 아키텍처 및 선행 작업 (GCP Console / Cloud Shell)

```text
[ GitHub Repository ]
        │ (git push to main/develop or manual trigger)
        ▼
[ GitHub Actions Runner ]
        │  1. google-github-actions/auth (Workload Identity or SA Key)
        │  2. Docker Build (Dockerfile)
        │  3. Docker Push
        ▼
[ Google Artifact Registry (GAR) ]
        │
        ▼ (gcloud run deploy)
[ Google Cloud Run (FastAPI Container) ]
        │ (포트 동적 바인딩: ${PORT:-8000})
        ├── Supabase PostgreSQL / pgvector (Transaction Pooler: 6543)
        ├── Upstash / Redis
        └── Google Gemini API / External APIs
```

#### 사전 인프라 세팅 명령어 (GCP Cloud Shell)
```bash
# 1. 환경 변수 정의
export PROJECT_ID="your-gcp-project-id"
export REGION="asia-northeast3" # 서울 리전
export REPO_NAME="dpyb-docker-repo"
export SA_NAME="github-actions-deployer"

# 2. 필수 GCP API 활성화
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  cloudbuild.googleapis.com \
  --project $PROJECT_ID

# 3. Artifact Registry Docker 저장소 생성
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$REGION \
  --description="DPYB Backend Docker Repository" \
  --project=$PROJECT_ID

# 4. GitHub Actions 전용 서비스 계정(Service Account) 생성 및 권한 부여
gcloud iam service-accounts create $SA_NAME \
  --display-name="GitHub Actions Deployer" \
  --project=$PROJECT_ID

# Artifact Registry 작성자 권한 부여
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Cloud Run 관리자 권한 부여
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"

# 서비스 계정 사용자(Service Account User) 권한 부여
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# 5. 서비스 계정 JSON 키 발급 (GitHub Secrets 등록용)
gcloud iam service-accounts keys create sa-key.json \
  --iam-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project=$PROJECT_ID
# (주의: sa-key.json 내용을 복사하여 GitHub Secret으로 저장 후 파일은 즉시 삭제할 것)
```

---

### 2.2 GitHub Repository Secrets 설정
해당 백엔드 레포(`backend-core-api` 또는 `backend-ai-agent`)의 `Settings` -> `Secrets and variables` -> `Actions`에 등록:

| Secret 이름 | 설명 | 예시 값 |
| :--- | :--- | :--- |
| `GCP_PROJECT_ID` | GCP 프로젝트 ID | `dpyb-prod-412345` |
| `GCP_SA_KEY` | 위에서 발급한 `sa-key.json` 전체 JSON 내용 | `{"type": "service_account", ...}` |
| `GCP_REGION` | 배포 리전 | `asia-northeast3` |
| `GAR_REPOSITORY` | Artifact Registry 이름 | `dpyb-docker-repo` |

---

### 2.3 GitHub Actions 워크플로우 템플릿 (`.github/workflows/deploy-gcp.yml`)

공식 `google-github-actions` 권장 표준을 적용한 자동/수동 배포 파이프라인입니다.

```yaml
name: Deploy to Google Cloud Run

on:
  workflow_dispatch: # 언제든 GitHub Actions 탭에서 수동 실행 가능
  push:
    branches:
      - main # 운영 배포 브랜치 (필요 시 develop 추가 가능)

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  REGION: ${{ secrets.GCP_REGION || 'asia-northeast3' }}
  GAR_REPOSITORY: ${{ secrets.GAR_REPOSITORY || 'dpyb-docker-repo' }}
  # 서비스명: 레포 이름에 맞춰 자동 매핑 (backend-ai-agent 또는 backend-core-api)
  SERVICE_NAME: ${{ github.event.repository.name }}

jobs:
  deploy:
    name: Build & Deploy to Cloud Run
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        id: auth
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Configure Docker for Artifact Registry
        run: |
          gcloud auth configure-docker ${{ env.REGION }}-docker.pkg.dev --quiet

      - name: Set Image Tag
        run: |
          IMAGE_URI="${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.GAR_REPOSITORY }}/${{ env.SERVICE_NAME }}:${{ github.sha }}"
          echo "IMAGE_URI=${IMAGE_URI}" >> $GITHUB_ENV
          echo "IMAGE_LATEST=${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.GAR_REPOSITORY }}/${{ env.SERVICE_NAME }}:latest" >> $GITHUB_ENV

      - name: Build and Push Container Image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.IMAGE_URI }}
            ${{ env.IMAGE_LATEST }}

      - name: Deploy to Cloud Run
        uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: ${{ env.SERVICE_NAME }}
          image: ${{ env.IMAGE_URI }}
          region: ${{ env.REGION }}
          flags: |
            --port=8000
            --allow-unauthenticated
            --cpu=1
            --memory=1Gi
            --min-instances=0
            --max-instances=5
            --timeout=300s

      - name: Show Service URL
        run: |
          echo "🚀 Cloud Run 배포 완료!"
          echo "엔드포인트 URL: ${{ steps.deploy.outputs.url }}"
```

> **💡 동적 포트 바인딩 호환성**:
> DPYB의 백엔드 Dockerfile은 `CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]` 형태로 작성되어 있으므로, Cloud Run이 주입하는 `$PORT` 환경변수와 완벽하게 호환됩니다.

---

## 3. AWS 전환 가이드 (대안 2순위 - App Runner)

AWS 환경으로 전환 시, ECS/EKS 같은 복잡한 인프라 관리 대신 GCP Cloud Run과 거의 동일한 CaaS 모델인 **AWS App Runner**를 사용하는 것이 가장 빠르고 간결합니다.

### 3.1 아키텍처
```text
[ GitHub Repository ] ──▶ [ GitHub Actions ] ──▶ [ AWS ECR (컨테이너 레지스트리) ] ──▶ [ AWS App Runner ]
```

### 3.2 필요 GitHub Secrets
* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_REGION` (`ap-northeast-2` 서울)

### 3.3 GitHub Actions 워크플로우 템플릿 (`.github/workflows/deploy-aws.yml`)

```yaml
name: Deploy to AWS App Runner

on:
  workflow_dispatch:
  push:
    branches:
      - main

env:
  AWS_REGION: ap-northeast-2
  ECR_REPOSITORY: ${{ github.event.repository.name }}
  APP_RUNNER_SERVICE: ${{ github.event.repository.name }}

jobs:
  deploy:
    name: Build & Push to ECR, Deploy to App Runner
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push Docker image
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $REGISTRY/$ECR_REPOSITORY:latest
          docker push $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $REGISTRY/$ECR_REPOSITORY:latest

      - name: Deploy to App Runner
        run: |
          SERVICE_ARN=$(aws apprunner list-services --query "ServiceSummaryList[?ServiceName=='${{ env.APP_RUNNER_SERVICE }}'].ServiceArn" --output text)
          if [ -n "$SERVICE_ARN" ]; then
            echo "Starting App Runner Deployment for $SERVICE_ARN"
            aws apprunner start-deployment --service-arn $SERVICE_ARN
          else
            echo "⚠️ App Runner 서비스(${{ env.APP_RUNNER_SERVICE }})가 콘솔에서 생성되지 않았습니다."
            echo "최초 1회는 AWS App Runner 콘솔에서 ECR 이미지 연동으로 서비스를 생성해주세요."
          fi
```

---

## 4. 환경 변수 및 DB(Supabase) 연동 유의사항

GCP Cloud Run이나 AWS로 이전하더라도 데이터베이스(Supabase PostgreSQL / pgvector)와 Redis는 그대로 유지됩니다. 클라우드 콘솔 환경변수 설정 시 아래 항목을 반드시 점검해야 합니다:

1. **Supabase 풀러 포트 6543 필수 사용**:
   * Cloud Run/App Runner는 다중 인스턴스로 오토스케일링될 수 있으므로, Supabase 세션 포트(5432) 대신 반드시 트랜잭션 풀러(`aws-0-ap-northeast-2.pooler.supabase.com:6543`)를 사용해야 DB 커넥션 고갈을 방지할 수 있습니다.
2. **비밀값 관리(Secret Manager)**:
   * `GEMINI_API_KEY`, `JWT_SECRET_KEY`, `DB_PASSWORD` 등은 일반 환경변수로 넣어도 무방하나, 운영 보안을 위해 GCP Secret Manager / AWS Secrets Manager에 등록 후 컨테이너 실행 시 마운트하는 것을 권장합니다.
3. **CORS 설정 동기화**:
   * 클라우드 배포 후 발급받은 신규 도메인(예: `https://backend-ai-agent-xyz-an.a.run.app`)을 `frontend-reader-web`의 API 엔드포인트 환경변수에 반영하고, 백엔드의 `ALLOWED_ORIGINS`에 프론트엔드 도메인을 등록합니다.
