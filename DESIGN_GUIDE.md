# NusuCheck (누수체크) — 디자인 가이드

> 상위 브랜드: 계발자들 (Vibers)
> 디자인 아이덴티티: 신뢰, 전문성, 편의성

## 컬러 시스템

### 핵심 컬러 팔레트
| 역할 | 값 | 설명 |
|------|-----|------|
| Primary | Blue 700-800 (#1D4ED8~#1E40AF) | 신뢰, 전문성 |
| AI/Innovation | Purple (#7C3AED) | AI 관련 기능 |
| Success | Green (#10B981) | 승인, 완료 |
| Warning | Yellow (#F59E0B) | 대기, 주의 |
| Danger | Red (#EF4444) | 거절, 오류 |
| Background | #F9FAFB | 페이지 배경 |
| Card | #FFFFFF | 카드 배경 |
| Text | #111827 | 기본 텍스트 |
| Text Sub | #6B7280 | 보조 텍스트 |

### 컬러 사용 규칙
- Hero 섹션: 배경 이미지 opacity 35-40%
- 카드 배경 이미지: opacity 12-15%
- Gradient overlay로 텍스트 가독성 확보
- 한국인/아시아인 모델 이미지 필수

## 타이포그래피

### 폰트 스택
- 한글: Noto Sans KR / Apple SD Gothic Neo
- 영문: system-ui, -apple-system

### 제목 계층
| 레벨 | 크기 | 용도 |
|------|------|------|
| H1 | 2.5rem (40px) | 히어로 제목 |
| H2 | 2rem (32px) | 섹션 제목 |
| H3 | 1.5rem (24px) | 서브 섹션 |
| Body | 1rem (16px) | 본문 |
| Small | 0.875rem (14px) | 보조 텍스트 |

## 레이아웃

### 반응형 브레이크포인트
- sm: 640px, md: 768px, lg: 1024px

### Mobile-first 접근
- 모바일 최우선 디자인
- Safe area 처리 (env(safe-area-inset-*))
- 최소 터치 영역 44px
- 하단 탭 바 고정 (bottom tabs)

## 컴포넌트 패턴

### 카드 (캐롯마켓 스타일)
- 둥근 모서리 (12-16px)
- 미묘한 그림자 (shadow-sm)
- 호버 시 shadow 강화
- `.card-hover` 클래스로 애니메이션

### 버튼
- Primary: bg-blue-700 hover:bg-blue-800 text-white
- Secondary: bg-gray-100 text-gray-700
- Danger: bg-red-600 text-white
- 로딩 상태: 비활성화 + 스피너

### 토스트 알림
- 하단에서 슬라이드 업 (toast-slide-in)
- 자동 사라짐 (3초)
- 성공(초록), 에러(빨강), 경고(노랑)

### 바텀 시트 (모바일)
- 드래그로 열기/닫기
- backdrop blur 배경
- slide-up 애니메이션

### 스켈레톤 로딩
- @keyframes shimmer (좌→우 반복)
- 실제 콘텐츠 영역과 동일한 크기

### 채팅 버블
- 보내기/받기 양방향
- bubble-fade-in 애니메이션
- 타이핑 인디케이터 (점 3개 반복)

### 비디오 업로드
- 드래그 앤 드롭 지원
- 업로드 진행률 바
- 미리보기 이미지

## 애니메이션 (application.css 기반)

### Turbo 통합
- Turbo 프로그래스 바 (상단)
- Frame 로딩 상태 (opacity transition)

### 폼 인터랙션
- 에러 필드: 빨간 테두리 + shake 애니메이션
- 성공 필드: 초록 테두리
- 포커스: ring-2 ring-blue-500

### 페이지 전환
- fade-in (opacity 0→1, translateY 10→0)
- 카드 순차 등장 (stagger)

### 로딩 바 (토스 스타일)
- 상단 고정, 파란색 프로그래스
- indeterminate 모드 지원

## 접근성
- WCAG 2.1 AA 기준
- 최소 터치 영역 44px
- focus-visible 상태 표시
- 모션 줄이기 (prefers-reduced-motion)
- 다크모드: 미지원 (향후 계획)

---

**마지막 업데이트**: 2026-03-24
