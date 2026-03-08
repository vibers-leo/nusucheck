# 누수체크 프로젝트 개발 가이드

> **⚠️ 중요: 모든 UI 개발 시 반드시 [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) 를 먼저 참조하세요.**
> 이 파일에는 색상, 타이포그래피, 컴포넌트, 페이지별 레이아웃 명세가 정의되어 있습니다.
> 새 페이지를 만들거나 기존 페이지를 수정할 때 DESIGN_SYSTEM.md의 규칙을 따라야 합니다.

## 프로젝트 개요
누수체크는 AI 기반 누수 감지, 전문가 매칭, 보험청구 자동화를 통합한 플랫폼입니다.
고객이 누수 문제를 쉽게 해결하고, 전문가(마스터)가 효율적으로 일할 수 있도록 돕습니다.

### 핵심 가치
- **투명성**: 표준 견적, 에스크로 결제를 통한 신뢰 구축
- **편의성**: AI 빠른 점검, 보험서류 자동화로 사용자 부담 최소화
- **전문성**: 검증된 전문가만 활동, 품질 보장

## 기술 스택
- **Backend**: Ruby on Rails 7.2
- **Frontend**: Tailwind CSS, Stimulus, Turbo
- **Real-time**: ActionCable (WebSocket)
- **Background Jobs**: Sidekiq
- **Database**: PostgreSQL
- **Cache**: Redis
- **Container**: Docker (개발 환경)
- **PDF**: Prawn
- **Authorization**: Pundit
- **State Machine**: AASM

## 개발 원칙

### 1. 단계별 체계적 접근
- 큰 작업은 명확한 단계로 나누어 진행
- 각 단계를 완료한 후 다음 단계로 이동
- 우선순위에 따라 순서를 조정할 수 있음
- 예: UI/UX → Admin Dashboard → Real-time Notifications → Docker Testing

### 2. UX/UI 품질 우선
- 시각적 완성도를 중요하게 생각
- 이미지, 애니메이션 등 디테일에 신경 쓰기
- 사용자 경험을 해치지 않는 범위에서 디자인 요소 추가
- 로딩 상태, 트랜지션 등 마이크로 인터랙션 구현

### 3. 문화적 적합성 (한국 시장 타겟)
- **이미지**: 사람이 등장하는 경우 반드시 한국인/아시아인 모델 사용
- **언어**: 모든 UI는 한국어로 작성
- **UX 패턴**: 한국 사용자에게 익숙한 UI/UX 패턴 사용
- **Unsplash 이미지 선택**: korean, asian 키워드 활용

### 4. 용어의 정확성
- 서비스 컨셉에 맞는 정확한 용어 사용
- **"신고" → "체크"**: 누수는 신고하는 것이 아니라 체크하는 것
- 사용자가 부담스럽지 않은 친근한 용어 선택
- 전문 용어는 필요한 경우에만 사용하고, 설명 추가

### 5. 시각적 요소 가시성
- 이미지는 충분히 보이도록 설정 (opacity 적절히 조정)
- 배경 이미지와 텍스트의 균형 유지
- Gradient overlay로 가독성 확보
- Hero 섹션: 35-40% opacity, 카드: 12-15% opacity 권장

### 6. 완전한 기능 구현
- 단순히 보여주기만 하는 기능은 지양
- 승인/수정/취소 등 필요한 모든 액션 구현
- 실시간 알림, 이메일 발송 등 사용자 경험 완성
- PDF 다운로드, 엑셀 내보내기 등 실용적 기능 제공

### 7. OKR 기반 의사결정
- 모든 작업은 OKR(Objectives and Key Results)과 연결되어야 함
- 기능 개발 전 "이것이 어떤 KR을 달성하는가?" 질문하기
- Output(할 일)이 아닌 Outcome(결과)에 집중
- 70% 달성 가능한 도전적 목표 설정
- 주간 체크인으로 진척도 확인 및 조정

## 코딩 컨벤션

### Rails
- **컨트롤러**: RESTful 액션 우선, 커스텀 액션은 member/collection으로 명확히 구분
- **서비스 객체**: 복잡한 비즈니스 로직은 `app/services`로 분리
- **Policy**: Pundit을 사용한 명시적 권한 관리
- **State Machine**: AASM으로 상태 전이 관리

### JavaScript (Stimulus)
- 컨트롤러는 단일 책임 원칙 준수
- 재사용 가능한 컴포넌트 형태로 작성
- 예: `loading_controller.js`, `button_loading_controller.js`

### CSS (Tailwind)
- Utility-first 접근, 커스텀 클래스는 최소화
- 재사용되는 스타일은 `@apply`로 컴포넌트화
- 애니메이션은 `application.css`에 정의
- 예: `.card-hover`, `.fade-in`, `.loading-bar`

## UX/UI 가이드라인

### 색상 체계
- **Primary**: Blue (700-800) - 신뢰, 전문성
- **Secondary**: Purple - AI, 혁신
- **Success**: Green - 승인, 완료
- **Warning**: Yellow - 대기, 주의
- **Danger**: Red - 거절, 오류

### 이미지 사용
1. **Hero 섹션**:
   - 배경 이미지 opacity 35-40%
   - Gradient overlay로 텍스트 가독성 확보
   - 서비스 컨셉과 관련된 이미지 (물, 파이프 등)

2. **프로세스 카드**:
   - 카드 배경 이미지 opacity 12-15%
   - 한국인/아시아인 모델 필수
   - 카드 내용과 관련된 이미지 선택

3. **Unsplash 이미지 URL 형식**:
   ```
   https://images.unsplash.com/photo-[ID]?w=[width]&auto=format&fit=crop
   ```

### 인터랙션
- **호버 효과**: shadow 변화, transform scale 등
- **로딩 상태**: 버튼 비활성화 + 스피너 표시
- **페이지 전환**: 상단 로딩 바 표시 (Turbo)
- **카드 애니메이션**: fade-in, card-hover 클래스 활용

### 반응형
- Mobile-first 접근
- 중단점: sm(640px), md(768px), lg(1024px)
- 모바일에서 메뉴는 햄버거 메뉴로 표시

## 용어 규칙

### 일관된 용어 사용
- **체크**: 누수 접수/신고 (request)
- **마스터**: 누수 전문가 (master)
- **고객**: 서비스 이용자 (customer)
- **견적**: 작업 견적서 (estimate)
- **보험청구**: 보험청구서 (insurance_claim)
- **에스크로**: 안전 결제 (escrow_transaction)

### 상태 표현
- **대기중**: pending
- **진행중**: in_progress, ongoing
- **완료**: completed
- **승인**: approved
- **거절**: rejected
- **취소**: cancelled

## 실시간 기능

### ActionCable 사용
- 알림은 WebSocket을 통해 실시간 전송
- `NotificationService`를 통한 중앙 집중식 관리
- 브로드캐스트 채널: `notification_channel.rb`
- 프론트엔드: `notification_controller.js`

### 알림 타입
- `request_assigned`: 체크 배정 (마스터에게)
- `estimate_received`: 견적 수신 (고객에게)
- `insurance_review_requested`: 보험청구서 검토 요청
- `escrow_deposited`: 에스크로 입금 완료

## Docker 환경

### 서비스 구성
- `db`: PostgreSQL 16
- `redis`: Redis 7
- `web`: Rails 서버 (포트 3000)
- `sidekiq`: 백그라운드 작업
- `tailwind`: CSS 빌드 watch

### 개발 워크플로우
```bash
# 환경 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f web

# 마이그레이션
docker-compose exec web bin/rails db:migrate

# 콘솔
docker-compose exec web bin/rails console

# 환경 종료
docker-compose down
```

## OKR 기반 개발 프로세스

### OKR이란?
OKR(Objectives and Key Results)은 도전적인 목표(Objective)와 측정 가능한 핵심 결과(Key Results)로 구성된 성과 관리 체계입니다. 누수체크 프로젝트의 모든 개발 작업은 OKR과 연결되어야 합니다.

**관련 문서**: [OKR.md](OKR.md) 참조

### 핵심 원칙

#### 1. Outcome 중심 사고
- ❌ **잘못된 접근**: "보험청구서 PDF 생성 기능을 만든다" (Output)
- ✅ **올바른 접근**: "보험청구 서류 자동화율 100%를 달성한다" (Outcome)

#### 2. 비즈니스 가치 우선
- 모든 작업 전 질문하기: "이것이 고객 만족도 95%에 어떻게 기여하는가?"
- 단순 할 일 목록이 아닌, 비즈니스 임팩트 중심으로 우선순위 결정

#### 3. 측정 가능성
- 주관적 표현(예: "사용자 경험 개선") 대신 구체적 지표 사용
- 예: "페이지 로딩 속도 3초 → 1초 단축", "고객 이탈률 50% → 20% 감소"

### 개발 전 체크리스트

모든 작업 시작 전 다음을 확인하세요:

1. **OKR 연결성 확인**
   - [ ] 이 작업이 달성하고자 하는 KR이 무엇인가?
   - [ ] 완료 후 측정 가능한 결과가 명확한가?
   - [ ] 사용자(고객/마스터)에게 어떤 가치를 제공하는가?

2. **우선순위 검증**
   - [ ] 현재 분기 OKR과 직접 연결되는가?
   - [ ] 다른 작업 대비 임팩트가 큰가?
   - [ ] 리소스 대비 효과가 충분한가?

3. **성공 기준 정의**
   - [ ] 완료 기준이 명확한가? (예: 정확도 85%, 처리 시간 24시간 이내)
   - [ ] 측정 방법이 구체적인가?
   - [ ] 목표치가 도전적이면서 달성 가능한가? (70% 달성 가능)

### 주간 OKR 체크인

매주 다음을 진행합니다:

#### 월요일: 주간 목표 설정
```markdown
## Week N OKR Check-in

### 이번 주 집중 KR
- KR 1: [현재 상태] → [목표 상태]
- KR 2: [현재 상태] → [목표 상태]

### 주간 Initiative
- [ ] 작업 A (예상 소요: 1일) - KR 1 기여
- [ ] 작업 B (예상 소요: 2일) - KR 2 기여
- [ ] 작업 C (예상 소요: 1일) - KR 1, 2 기여

### 블로커 및 리스크
- 없음 / [구체적 블로커 기술]
```

#### 금요일: 주간 회고
```markdown
## Week N 완료 보고

### 완료된 작업
- [x] 작업 A - KR 1: 50% → 65% 달성 ✅
- [ ] 작업 B - 50% 완료, 다음 주 계속 진행

### 배운 점 (Lessons Learned)
- 예상보다 시간이 오래 걸린 이유
- 더 효율적인 접근 방법 발견

### 다음 주 계획
- 작업 B 완료
- 새로운 작업 D 시작
```

### 분기 OKR 리뷰

분기 말에 다음을 수행합니다:

1. **최종 달성률 측정**
   - 각 KR별 달성률 계산 (0-100%)
   - 전체 평균 70% 이상 달성 시 성공으로 평가

2. **회고 (Retrospective)**
   - 잘된 점 (What went well)
   - 개선할 점 (What could be improved)
   - 배운 점 (Lessons learned)
   - 다음 분기에 적용할 점 (Action items)

3. **다음 분기 OKR 수립**
   - 이번 분기 결과를 바탕으로 조정
   - 새로운 목표와 핵심 결과 설정

### OKR 준수 예시

#### ❌ 잘못된 예시
**작업**: "관리자 대시보드에 차트 3개 추가"
- 문제: Output 중심, 비즈니스 가치 불명확

#### ✅ 올바른 예시
**KR**: "전문가 매칭 성공률 90% 달성"
**Initiative**:
- 관리자 대시보드에 매칭 성공률 실시간 모니터링 차트 추가
- 매칭 실패 원인 분석 리포트 구현
- 자동 알림 시스템으로 매칭 지연 24시간 이내 해결

**측정**: 매칭 성공률 = (견적 제공 완료 / 전체 체크 접수) × 100

### 참고 자료
- 📄 [OKR.md](OKR.md): 전체 OKR 상세 내용
- 📊 주간 체크인 템플릿
- 📈 분기 리뷰 가이드

---

## 테스트 및 배포

### 테스트 전 체크리스트
- [ ] Docker 환경에서 정상 실행 확인
- [ ] 주요 기능 동작 테스트
- [ ] 반응형 디자인 확인 (모바일, 태블릿, 데스크톱)
- [ ] 실시간 알림 동작 확인
- [ ] PDF 생성 테스트
- [ ] 이메일 발송 테스트 (development 환경)

## 참고 사항

### 주요 파일 위치
- **알림 시스템**: `app/services/notification_service.rb`
- **헬퍼**: `app/helpers/notifications_helper.rb`
- **채널**: `app/channels/notification_channel.rb`
- **컨트롤러**: `app/javascript/controllers/notification_controller.js`
- **스타일**: `app/assets/stylesheets/application.css`

### 외부 리소스
- **Unsplash**: 무료 고품질 이미지 (한국인/아시아인 모델 우선)
- **Heroicons**: SVG 아이콘 (Tailwind와 호환)
- **Google Fonts**: 필요시 한국어 웹폰트 (Noto Sans KR 등)

---

**마지막 업데이트**: 2026-02-13
**버전**: 1.1 (OKR 지침 추가)
