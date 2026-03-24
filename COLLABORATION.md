# NusuCheck (누수체크) — 에이전트 협업 프로토콜

AI 간 협업을 위한 공유 메시지 보드. 모든 에이전트는 작업 전/후에 이 문서를 확인하고 업데이트.

## 에이전트 구성
| 에이전트 | 담당 | 주요 파일 | 태그 |
|---------|------|---------|------|
| AntiGravity | 코딩 메인 | app/ 전체 | [AG] |
| Claude Code (VS Code) | 단일 작업 | 특정 기능 단위 | [CC] |
| Claude Code (터미널) | 병렬 작업 | 전체 | [TCC] |
| Claude Code (App) | 보조 | config/, db/ | [APP] |
| Claude Cowork | 비코딩 | 문서, 서버 관리 | [CW] |

## 협업 규칙

### Git 작업 규칙
- `git add .` 사용 금지 → 항상 `git add <파일명>`
- 커밋 전 반드시 `git pull origin main`
- 커밋 메시지 앞에 에이전트 태그: `[AG]`, `[CC]`, `[TCC]`, `[APP]`
- 커밋 전 `git diff --name-only`로 내 영역만 수정했는지 확인

### 공유 파일 수정 프로토콜
- Gemfile, config/routes.rb, application.css 등 공유 파일은:
  1. 알림 섹션에 "🔒 [{태그}] {파일} 수정 예정" 작성
  2. 수정 완료 후 "✅ 수정 완료" 업데이트
  3. 🔒 표시 중에는 다른 에이전트 수정 자제

## 작업 영역 분리

### 사용자 유형별
| 영역 | 주요 파일 | 담당 |
|------|---------|------|
| 고객 (Customer) | customers/ 컨트롤러, 뷰 | [AG] 우선 |
| 마스터 (Expert) | expert/, masters/ 컨트롤러 | [CC] |
| 관리자 (Admin) | admin/ 컨트롤러 | [TCC] |
| 공개 페이지 | pages_controller, posts/ | [APP] |

### 기능별
| 영역 | 주요 파일 | 담당 |
|------|---------|------|
| 인증/권한 | Devise, Pundit policies | [AG] |
| 체크 요청 | requests/, estimates/ | [AG] |
| 에스크로 결제 | escrow_transactions/, payments/ | [AG] |
| 보험청구 | insurance_claims/, CODEF API | [CC] |
| AI 누수 분석 | leak_inspections/, Claude Vision | [CC] |
| 알림 시스템 | notifications/, ActionCable | [TCC] |
| PDF/이메일 | Prawn, mailers/ | [TCC] |
| 배경 작업 | Sidekiq jobs | [TCC] |
| 인프라/배포 | Docker, .github/workflows | [CW] |

## 메시지 로그

### 2026-03-24
- [CW] NCP Docker 배포 완료
- [CW] 프로젝트 공통 지침 파일 세팅 (CLAUDE.md 보강, DESIGN_GUIDE.md, COLLABORATION.md 생성)

## 알림
- (없음)

## 커밋 전 체크리스트
- [ ] `git pull origin main` 실행
- [ ] `git diff --name-only`로 내 영역만 수정 확인
- [ ] `git add <특정 파일>` (git add . 금지)
- [ ] 커밋 메시지에 `[AG]`/`[CC]`/`[TCC]`/`[APP]` 태그
- [ ] COLLABORATION.md 메시지 로그 기록
