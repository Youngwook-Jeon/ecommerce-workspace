# ecommerce-workspace

MSA 이커머스 **백엔드 · 프론트엔드 · 로컬 인프라**를 한 워크스페이스에서 실행하기 위한 메타 저장소입니다.

앱 코드는 각각 별도 GitHub 저장소에 있으며, 이 레포는 `Makefile` / `scripts/` 로 기동·중지를 묶습니다.

| 경로 | 저장소 | 역할 |
|------|--------|------|
| (루트) | [ecommerce-workspace](https://github.com/Youngwook-Jeon/ecommerce-workspace) | 실행 오케스트레이션 |
| `ecommerce-msa/` | [ecommerce-msa](https://github.com/Youngwook-Jeon/ecommerce-msa) | Gateway · 마이크로서비스 · Docker 인프라 |
| `ecommerce-frontend/` | [ecommerce-frontend](https://github.com/Youngwook-Jeon/ecommerce-frontend) | Next.js 스토어프론트 · 관리자 UI |

상세 아키텍처·도메인 설명은 각 서브모듈 README를 참고하세요.

---

## 사전 요구 사항

| 도구 | 용도 |
|------|------|
| **JDK 21** | Spring 서비스 빌드·실행 |
| **Docker / Docker Compose** | Postgres, Kafka, Keycloak, Debezium 등 인프라 |
| **kcat**, **jq**, **nc** | 인프라 헬스체크 · Debezium 등록 스크립트 |
| **Bun** | 프론트엔드 (`make frontend`) |
| (선택) **Stripe CLI** | `PAYMENT_PROVIDER=stripe` 일 때 웹훅 포워딩 |

사전 도구 확인:

```bash
make check-prereqs
```

---

## Clone

```bash
git clone --recurse-submodules https://github.com/Youngwook-Jeon/ecommerce-workspace.git
cd ecommerce-workspace
```

이미 clone만 했다면:

```bash
git submodule update --init --recursive
```

---

## 빠른 실행 (권장)

### 1. 백엔드 환경 파일 (최초 1회)

```bash
cp ecommerce-msa/.env.example ecommerce-msa/.env
```

기본값은 `PAYMENT_PROVIDER=stub`, `R2_ENABLED=false` 이라 **Stripe / Cloudflare 키 없이** 기동됩니다.

### 2. 인프라 + 백엔드 + Debezium

워크스페이스 **루트**에서:

```bash
make up
```

순서: Docker 인프라 → Maven 빌드 → 서비스 기동(Flyway 포함) → Debezium 커넥터 등록.

완료 후 대략 아래 URL을 사용할 수 있습니다.

| 구분 | URL |
|------|-----|
| **앱 진입 (Gateway)** | http://localhost:9000 |
| Kafka UI | http://localhost:9090 |
| Kafka Connect | http://localhost:8083 |
| Keycloak | http://localhost:8080 |

백엔드 포트:

| 서비스 | 포트 |
|--------|------|
| edge-service (Gateway) | 9000 |
| product-service | 9002 |
| order-service | 9003 |
| payment-service | 9004 |

로그 · PID: `.run/logs/`, `.run/pids/`

### 3. 프론트엔드

```bash
make frontend
```

Next.js는 `http://localhost:3000` 에서 뜨고, Gateway가 SPA로 프록시합니다.

**브라우저는 항상 `http://localhost:9000` 으로 접속하세요.**  

### 4. 중지

```bash
make down
```

앱 프로세스와 인프라 컨테이너를 중지합니다. (Docker 볼륨은 유지)

---

## 관리자 로그인

어드민·상품 관리 등 `ADMIN` 역할이 필요한 기능은 Gateway(`:9000`)에서 로그인합니다.

| 항목 | 값 |
|------|-----|
| 이메일 | `lucas@lucas.com` |
| 비밀번호 | `password` |

로컬 Keycloak Realm `Ecomart` 에 시드된 테스트 계정입니다.  
Keycloak 콘솔: http://localhost:8080 (관리자 `admin` / `admin`)

---

## 선택: Stripe 실결제

1. `ecommerce-msa/.env`

   ```bash
   PAYMENT_PROVIDER=stripe
   STRIPE_API_KEY=sk_test_...
   ```

   `STRIPE_WEBHOOK_SECRET`은 넣지 않아도 됩니다. `make up` / `make apps` 가 Stripe CLI로 `whsec_` 를 받아 주입하고, `stripe listen` 을 백그라운드로 띄웁니다. (`make down` 시 함께 종료)

2. `ecommerce-frontend/.env.local` (예시는 `.env.example`)

   ```bash
   NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
   ```

3. 다시 `make apps` 또는 `make up`

웹훅 이벤트 로그를 포그라운드에서 보려면: `make stripe-listen`

---

## 선택: Cloudflare R2 (상품 이미지)

기본은 로컬 stub(`R2_ENABLED=false`). 실제 R2를 쓰려면 `ecommerce-msa/.env` 에 엔드포인트·키·버킷을 설정하고 `R2_ENABLED=true` 로 바꿉니다.  
자세한 키 목록은 `ecommerce-msa/.env.example` 참고.

---

## 자주 쓰는 Make 타깃

| 명령 | 설명 |
|------|------|
| `make up` | 인프라 + 빌드 + 앱 + Debezium |
| `make down` | 앱 · 인프라 중지 |
| `make infra-up` / `infra-stop` / `infra-reset` | 인프라만 |
| `make build` | `mvn clean install -DskipTests` |
| `make apps` / `apps-stop` / `apps-wait` | 앱만 기동 · 중지 · 준비 대기 |
| `make apps-restart-payment` | payment-service만 재시작 |
| `make debezium` | Debezium 커넥터만 재등록 |
| `make frontend` | `bun run dev` |
| `make package` | JAR 패키징 |
| `make run-jar SERVICE=payment` | 패키지된 JAR로 단일 서비스 실행 |
| `make stripe-listen` | Stripe 웹훅 listen (포그라운드) |
| `make check-prereqs` | 필수 도구 검사 |
| `make help` | 타깃 목록 |


---

## 더 알아보기

- 백엔드 · 인프라 · Debezium · 수동 기동: [`ecommerce-msa/README.md`](ecommerce-msa/README.md)
- 프론트엔드 · BFF · 관리자 UI: [`ecommerce-frontend/README.md`](ecommerce-frontend/README.md)
- Debezium Outbox CDC: [`ecommerce-msa/deployment/docker/DEBEZIUM.md`](ecommerce-msa/deployment/docker/DEBEZIUM.md)
