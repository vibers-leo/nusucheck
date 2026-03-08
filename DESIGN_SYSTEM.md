# 누수체크 디자인 시스템 v2.0

> **이 문서는 모든 페이지 개발 시 반드시 참조해야 하는 디자인 가이드입니다.**
> Claude Code가 새로운 페이지를 만들거나 기존 페이지를 수정할 때 이 문서의 규칙을 따르세요.

---

## 1. 디자인 철학

### 레퍼런스 앱
| 앱 | 적용 포인트 |
|---|---|
| **당근마켓** | 카드 UI, 리스트 아이템, 하단 탭 네비게이션, 따뜻한 톤 |
| **토스** | 단계형 위자드, 히어로 섹션, 큰 타이포그래피, 깔끔한 정보 구조 |
| **미소** | 서비스 예약 플로우, 리뷰/신뢰 표시, 전문가 프로필 카드 |

### 핵심 원칙
1. **모바일 퍼스트**: 모든 레이아웃은 모바일(375px)을 기준으로 설계 후 데스크톱 확장
2. **카드 기반 UI**: 모든 정보 블록은 rounded-2xl 카드 안에 배치
3. **1화면 1목적**: 각 화면은 하나의 주요 액션에 집중
4. **친근한 톤**: "신고" 대신 "체크", 이모지 활용, 부드러운 문구

---

## 2. 색상 시스템

### Primary (Teal)
```
primary-50:  #f0fdfa   → 배경 하이라이트
primary-100: #ccfbf1   → 뱃지 배경, 아이콘 배경
primary-200: #99f6e4   → 호버 배경
primary-600: #0d9488   → 메인 버튼, 활성 탭, 링크 텍스트
primary-700: #0f766e   → 버튼 호버, 진한 강조
primary-800: #115e59   → 다크 배경 텍스트
```

### Secondary (Purple) - AI/혁신 관련
```
purple-50:  #faf5ff    → AI 기능 배경
purple-100: #f3e8ff    → AI 뱃지 배경
purple-600: #9333ea    → AI 강조, 그라디언트 끝점
```

### Accent (Orange) - 당근마켓 스타일 포인트
```
carrot-400: #fb923c    → 가격, 카운트 강조
carrot-500: #f97316    → CTA 보조 버튼
```

### 상태 색상
```
승인/완료 (green):  bg-green-100 text-green-700
대기/진행 (yellow): bg-yellow-100 text-yellow-700
배정/처리 (blue):   bg-blue-100 text-blue-700
거절/오류 (red):    bg-red-100 text-red-700
접수/기본 (gray):   bg-gray-100 text-gray-700
AI분석 (purple):    bg-purple-100 text-purple-700
```

### 그라디언트 (히어로/CTA 전용)
```html
<!-- 기본 히어로 그라디언트 -->
bg-gradient-to-r from-primary-600 to-primary-700

<!-- AI/프리미엄 그라디언트 -->
bg-gradient-to-r from-primary-600 to-purple-600

<!-- 랜딩페이지 배경 그라디언트 -->
bg-gradient-to-br from-primary-50 via-white to-purple-50
```

### ❌ 색상 사용 금지 사항
- `bg-blue-600`, `bg-indigo-600` 등 primary가 아닌 파란 계열 사용 금지
- 그라디언트는 히어로 섹션/CTA 버튼에만 사용, 카드 내부에는 사용 금지
- 카드 배경은 항상 `bg-white` (다크모드 미지원)

---

## 3. 타이포그래피

### 폰트
```
font-family: 'Pretendard Variable', 'Pretendard', system-ui, sans-serif
```

### 크기 체계
| 용도 | 클래스 | 굵기 |
|---|---|---|
| 페이지 제목 (히어로) | `text-[26px]` ~ `text-5xl` | `font-extrabold` |
| 섹션 제목 | `text-lg` ~ `text-xl` | `font-bold` |
| 카드 제목 | `text-base` | `font-bold` |
| 본문 텍스트 | `text-sm` (14px) | `font-medium` |
| 부가 정보 | `text-xs` (12px) | `font-medium` 또는 기본 |
| 뱃지/태그 | `text-xs` | `font-bold` |
| 큰 숫자 (통계) | `text-2xl` ~ `text-4xl` | `font-extrabold` |

### 색상 체계
```
제목/강조:  text-gray-900
본문:       text-gray-700 또는 text-gray-600
부가정보:   text-gray-500
비활성:     text-gray-400
링크:       text-primary-600 hover:text-primary-700
```

---

## 4. 간격 & 레이아웃

### 기본 간격 (8px 그리드)
```
섹션 간 간격:    mb-6 (24px)
카드 내부 패딩:  p-5 (20px) 또는 p-4 (16px)
카드 간 간격:    space-y-3 (12px) 또는 gap-3 (12px)
요소 내 간격:    gap-2 (8px) 또는 gap-3 (12px)
아이콘-텍스트:   gap-2 (8px)
```

### 페이지 컨테이너
```html
<!-- 모바일 기본 컨테이너 -->
<div class="min-h-screen bg-gray-50 pb-20 md:pb-8">
  <div class="max-w-4xl mx-auto px-4 py-6 md:pt-0">
    <!-- 콘텐츠 -->
  </div>
</div>
```
- `pb-20`: 하단 네비게이션 공간 확보 (모바일)
- `md:pb-8`: 데스크톱에서는 일반 패딩
- `max-w-4xl`: 최대 너비 896px
- `px-4`: 좌우 패딩 16px

### 그리드
```html
<!-- 3열 그리드 (빠른 액션, 통계) -->
<div class="grid grid-cols-3 gap-3">

<!-- 2열 그리드 (카드 목록) -->
<div class="grid grid-cols-1 md:grid-cols-2 gap-4">

<!-- 리스트 (세로 나열) -->
<div class="space-y-3">
```

---

## 5. 컴포넌트 라이브러리

### 5.1 버튼

#### Primary 버튼 (메인 CTA)
```html
<button class="w-full px-6 py-4 bg-primary-600 text-white rounded-2xl hover:bg-primary-700
               transition-all font-bold text-base shadow-md active:scale-[0.98]">
  누수 체크 접수하기
</button>
```

#### Secondary 버튼
```html
<button class="w-full px-6 py-4 bg-white text-gray-700 rounded-2xl hover:bg-gray-50
               transition-all font-semibold text-base border-2 border-gray-200">
  이전으로
</button>
```

#### Ghost 버튼 (텍스트형)
```html
<button class="px-4 py-2 text-primary-600 hover:text-primary-700 hover:bg-primary-50
               rounded-xl transition-all font-semibold text-sm">
  전체 보기 →
</button>
```

#### 아이콘 버튼
```html
<button class="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center
               hover:bg-gray-200 transition-colors">
  <svg class="w-5 h-5 text-gray-600">...</svg>
</button>
```

#### ❌ 버튼 규칙
- 모바일에서 주요 CTA는 항상 `w-full`
- `rounded-2xl` 통일 (rounded-lg, rounded-md 사용 금지)
- 그라디언트 버튼은 랜딩페이지/최종 CTA에서만 사용

### 5.2 카드

#### 기본 카드
```html
<div class="bg-white rounded-2xl p-5 border-2 border-gray-100">
  <!-- 카드 내용 -->
</div>
```

#### 인터랙티브 카드 (링크/클릭 가능)
```html
<%= link_to path, class: "block bg-white rounded-2xl p-5 hover:shadow-lg transition-all
                          border-2 border-gray-100 hover:border-primary-200 card-hover" do %>
  <!-- 카드 내용 -->
<% end %>
```

#### 강조 카드 (인사 카드, 프로모션)
```html
<div class="bg-gradient-to-r from-primary-600 to-primary-700 rounded-3xl p-6 text-white shadow-lg">
  <!-- 카드 내용 -->
</div>
```

#### 알림/가이드 카드
```html
<div class="bg-primary-50 rounded-2xl p-5 border-2 border-primary-100">
  <h3 class="text-sm font-bold text-primary-900 mb-3 flex items-center gap-2">
    <span>💡</span>
    <span>이용 가이드</span>
  </h3>
  <p class="text-xs text-primary-800">안내 내용</p>
</div>
```

#### 경고/주의 카드
```html
<div class="bg-orange-50 rounded-2xl p-4 border border-orange-200">
  <p class="text-sm text-orange-800 font-medium">⏳ 전문가 매칭 중...</p>
</div>
```

#### 카드 규칙
- 카드 배경: 항상 `bg-white`
- 카드 테두리: `border-2 border-gray-100` (당근마켓 스타일)
- 카드 라운드: `rounded-2xl` (기본) 또는 `rounded-3xl` (강조)
- shadow는 호버 시에만: `hover:shadow-lg`
- 기본 상태에서는 shadow 없이 border만 사용

### 5.3 상태 뱃지
```html
<!-- 공통 뱃지 패턴 -->
<span class="px-2 py-1 bg-{color}-100 text-{color}-700 rounded-full text-xs font-bold">
  상태 텍스트
</span>

<!-- 예시 -->
<span class="px-2 py-1 bg-primary-100 text-primary-700 rounded-full text-xs font-bold">진행중</span>
<span class="px-2 py-1 bg-green-100 text-green-700 rounded-full text-xs font-bold">✓ 완료</span>
<span class="px-2 py-1 bg-yellow-100 text-yellow-700 rounded-full text-xs font-bold">견적 대기</span>
<span class="px-2 py-1 bg-red-100 text-red-700 rounded-full text-xs font-bold">거절됨</span>
```

### 5.4 아이콘 서클 (빠른 액션)
```html
<!-- 크기: w-14 h-14 (기본), w-12 h-12 (작은), w-10 h-10 (아주 작은) -->
<div class="w-14 h-14 bg-primary-100 rounded-full flex items-center justify-center">
  <svg class="w-8 h-8 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="..."/>
  </svg>
</div>
```

색상 변형:
```
primary: bg-primary-100 + text-primary-600
green:   bg-green-100 + text-green-600
purple:  bg-purple-100 + text-purple-600
orange:  bg-orange-100 + text-orange-600
blue:    bg-blue-100 + text-blue-600
gray:    bg-gray-100 + text-gray-600
```

### 5.5 리스트 아이템 (당근마켓 스타일)
```html
<%= link_to path, class: "block bg-white rounded-2xl p-5 hover:shadow-lg transition-all
                          border-2 border-gray-100 hover:border-primary-200" do %>
  <!-- 상단: 뱃지 + 시간 -->
  <div class="flex items-center gap-2 mb-3">
    <span class="px-2 py-1 bg-primary-100 text-primary-700 rounded-full text-xs font-bold">
      진행중
    </span>
    <span class="text-xs text-gray-500">2시간 전</span>
  </div>

  <!-- 제목 -->
  <h3 class="font-bold text-gray-900 mb-2 text-base">배관 누수</h3>

  <!-- 주소 (아이콘 + 텍스트) -->
  <div class="flex items-start gap-2 mb-3">
    <svg class="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>
    </svg>
    <p class="text-sm text-gray-600 line-clamp-1">서울시 강남구 역삼동 123-45</p>
  </div>

  <!-- 하단 정보 (전문가 카드 등) -->
  <div class="flex items-center gap-2 p-3 bg-gray-50 rounded-xl">
    <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
      <svg class="w-5 h-5 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
      </svg>
    </div>
    <div class="flex-1">
      <p class="text-xs text-gray-500">담당 전문가</p>
      <p class="text-sm font-semibold text-gray-900">김전문가</p>
    </div>
    <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
    </svg>
  </div>
<% end %>
```

### 5.6 빈 상태 (Empty State)
```html
<div class="bg-white rounded-2xl p-10 text-center border-2 border-dashed border-gray-200">
  <div class="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
    <svg class="w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <!-- 아이콘 -->
    </svg>
  </div>
  <p class="text-gray-600 mb-4 font-medium">데이터가 없어요</p>
  <p class="text-sm text-gray-500 mb-6">설명 텍스트</p>
  <%= link_to path, class: "inline-flex items-center gap-2 px-6 py-3 bg-primary-600 text-white
                            rounded-xl hover:bg-primary-700 transition-all font-bold shadow-md" do %>
    <svg class="w-5 h-5">...</svg>
    <span>액션 버튼</span>
  <% end %>
</div>
```

### 5.7 통계 카드
```html
<div class="bg-white rounded-2xl p-4 text-center border-2 border-gray-100">
  <p class="text-2xl font-extrabold text-primary-600">12</p>
  <p class="text-xs text-gray-600 mt-1">진행중</p>
</div>
```

### 5.8 폼 입력 필드
```html
<!-- 텍스트 입력 -->
<div class="mb-4">
  <label class="block text-sm font-bold text-gray-700 mb-2">라벨</label>
  <input type="text"
         class="w-full px-4 py-3.5 bg-gray-50 border-2 border-gray-200 rounded-2xl text-base
                focus:border-primary-500 focus:ring-2 focus:ring-primary-100 focus:bg-white
                transition-all placeholder-gray-400"
         placeholder="입력해주세요">
</div>

<!-- 텍스트영역 -->
<textarea class="w-full px-4 py-3.5 bg-gray-50 border-2 border-gray-200 rounded-2xl text-base
                 focus:border-primary-500 focus:ring-2 focus:ring-primary-100 focus:bg-white
                 transition-all placeholder-gray-400 resize-none"
          rows="4" placeholder="상세 내용을 입력해주세요"></textarea>

<!-- 선택 카드 (위자드 스타일) -->
<label class="block bg-white rounded-2xl p-5 border-2 border-gray-200 cursor-pointer
              hover:border-primary-300 transition-all peer-checked:border-primary-500
              peer-checked:bg-primary-50">
  <input type="radio" name="option" value="1" class="peer hidden">
  <div class="flex items-center gap-3">
    <div class="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
      <svg class="w-5 h-5 text-primary-600">...</svg>
    </div>
    <div>
      <p class="font-bold text-gray-900">옵션 제목</p>
      <p class="text-sm text-gray-500">설명 텍스트</p>
    </div>
  </div>
</label>
```

### 5.9 토스트 알림
```html
<div class="fixed bottom-20 md:bottom-6 left-1/2 -translate-x-1/2 z-50 w-[calc(100%-2rem)] max-w-sm">
  <div class="bg-gray-900 text-white px-4 py-3 rounded-2xl flex items-center justify-between shadow-lg">
    <div class="flex items-center gap-2">
      <svg class="w-5 h-5 text-green-400">...</svg>
      <span class="text-sm font-medium">저장되었습니다</span>
    </div>
    <button class="text-gray-400 hover:text-white">
      <svg class="w-4 h-4">...</svg>
    </button>
  </div>
</div>
```

### 5.10 페이지 헤더 (뒤로가기)
```html
<div class="mb-5">
  <%= link_to back_path, class: "inline-flex items-center text-sm text-gray-500
                                 hover:text-gray-900 transition-colors mb-2" do %>
    <svg class="w-5 h-5 mr-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
    </svg>
    <span>돌아가기</span>
  <% end %>
  <h1 class="text-[22px] font-bold text-gray-900"><%= title %></h1>
  <% if local_assigns[:subtitle] %>
    <p class="text-sm text-gray-500 mt-1"><%= subtitle %></p>
  <% end %>
</div>
```

---

## 6. 네비게이션

### 6.1 하단 탭 네비게이션 (모바일, 고객 앱)
```html
<nav class="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50 md:hidden">
  <div class="flex items-center justify-around h-16">
    <!-- 각 탭 아이템 -->
    <%= link_to path, class: "flex flex-col items-center justify-center flex-1 h-full
                              #{active ? 'text-primary-600' : 'text-gray-500'}
                              hover:text-primary-600 transition-colors" do %>
      <svg class="w-6 h-6 mb-1">...</svg>
      <span class="text-[10px] font-semibold">탭명</span>
    <% end %>
  </div>
</nav>
```

탭 구성 (고객):
1. 🏠 홈 (`customers_dashboard_path`)
2. 📋 내 요청 (`customers_requests_path`)
3. ➕ 새 체크 (`new_customers_request_path`) — 가운데 강조
4. 📄 보험 (`customers_insurance_claims_path`)
5. 👤 마이 (`customers_profile_path`)

### 6.2 데스크톱 상단 네비게이션 (고객)
```html
<header class="hidden md:block bg-white border-b border-gray-200 sticky top-0 z-40">
  <div class="max-w-4xl mx-auto px-4 h-14 flex items-center justify-between">
    <!-- 로고 -->
    <a href="/" class="text-lg font-bold text-primary-600">누수체크</a>

    <!-- 네비게이션 링크 -->
    <nav class="flex items-center gap-6">
      <a class="text-sm font-medium text-gray-600 hover:text-primary-600">홈</a>
      <a class="text-sm font-medium text-gray-600 hover:text-primary-600">내 요청</a>
      <a class="text-sm font-medium text-gray-600 hover:text-primary-600">보험</a>
    </nav>

    <!-- 우측 액션 -->
    <div class="flex items-center gap-3">
      <!-- 알림 벨 -->
      <button class="relative p-2 text-gray-600 hover:bg-gray-50 rounded-lg">
        <svg class="w-5 h-5">...</svg>
        <span class="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
      </button>
      <!-- 프로필 -->
      <a class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
        <svg class="w-4 h-4 text-primary-600">...</svg>
      </a>
    </div>
  </div>
</header>
```

### 6.3 전문가(마스터) 네비게이션
- 데스크톱: 좌측 사이드바 (다크 배경 `bg-gray-900`)
- 모바일: 하단 탭 네비게이션 (고객과 동일 패턴)

### 6.4 관리자 네비게이션
- 데스크톱: 좌측 사이드바 (다크 teal `bg-primary-900`)
- 모바일: 햄버거 메뉴 → 드로어

---

## 7. 페이지별 디자인 명세

### 7.1 고객 앱 (customers/)

#### 랜딩페이지 (`pages/landing`)
- **레이아웃**: 토스 스타일 풀스크린 히어로
- **배경**: `bg-gradient-to-br from-primary-50 via-white to-purple-50`
- **히어로**: 큰 텍스트 (`text-5xl font-extrabold`), 그라디언트 텍스트 강조
- **CTA**: 2개 버튼 (Primary 그라디언트 + Secondary 화이트)
- **프로세스**: 3열 카드 (파랑/보라/핑크 그라디언트 배경)
- **특징**: 2x2 아이콘+텍스트 그리드
- **최종 CTA**: 풀 너비 그라디언트 배너

#### 대시보드 (`dashboard/index`)
- **레이아웃**: 당근마켓 스타일 카드 나열
- **인사 카드**: 그라디언트 배경 (`from-primary-600 to-primary-700`), 흰색 텍스트
- **빠른 액션**: 3열 그리드, 각 카드에 아이콘 서클 + 텍스트
- **통계**: 3열 그리드, 큰 숫자 + 작은 라벨
- **진행 중인 체크**: 리스트 아이템 (뱃지 + 제목 + 주소 + 전문가 정보)
- **빈 상태**: dashed border 카드 + CTA 버튼
- **가이드**: primary-50 배경 카드

#### 새 체크 접수 (`requests/new`)
- **레이아웃**: 토스 스타일 단계별 위자드 (7단계)
- **프로그레스**: 상단 바 (`bg-gradient-to-r from-primary-600 to-purple-600`)
- **질문**: 큰 텍스트 (`text-[22px] font-bold`)
- **선택지**: 세로 나열 카드 라디오 버튼
- **네비게이션**: 하단 고정 버튼 (이전/다음)
- **각 단계**: 누수유형 → 긴급도 → 위치 → 주소 → 상세 → 사진/영상 → 확인

#### 요청 목록 (`requests/index`)
- **레이아웃**: 상단 탭 필터 + 리스트
- **필터 탭**: 가로 스크롤, pill 스타일 (`rounded-full`)
- **리스트**: space-y-3, 리스트 아이템 패턴 반복
- **정렬**: 최신순 기본

#### 요청 상세 (`requests/show`)
- **레이아웃**: 상태 타임라인 + 정보 카드 나열
- **상태 바**: 5단계 도트 프로그레스 (`접수 → 배정 → 견적 → 시공 → 완료`)
- **정보 섹션**: 카드 형태로 구분 (기본정보, 사진/영상, 견적, 전문가)
- **액션 버튼**: 하단 고정 또는 카드 내부

#### 견적 상세 (`estimates/show`)
- **레이아웃**: 견적 요약 카드 + 항목 리스트 + 합계
- **합계**: 큰 숫자 강조 (`text-2xl font-extrabold text-primary-600`)
- **액션**: 수락/거절 버튼 쌍

#### 보험 신청 목록/상세 (`insurance_claims/`)
- **목록**: 리스트 아이템 패턴, 상태 뱃지 포함
- **상세**: 서류 정보 카드 + 상태 + 다운로드 링크
- **신규**: 폼 카드 나열, 파일 업로드 영역
- **수정**: 기존 데이터 프리필 + 수정 영역

#### 결제 (`payments/`)
- **체크아웃**: 주문 요약 카드 + 결제 방법 선택 + 토스페이먼츠 위젯
- **목록**: 결제 이력, 금액 강조

#### 프로필 (`profiles/`)
- **보기**: 아바타 + 정보 카드 + 메뉴 리스트
- **수정**: 폼 카드 + 이미지 업로드

#### 설정 (`settings/`)
- **레이아웃**: 메뉴 리스트 (당근마켓 마이페이지 스타일)
- **각 항목**: 아이콘 + 텍스트 + 화살표, 구분선

#### 리뷰 작성 (`reviews/new`)
- **별점**: 큰 별 5개 (터치 친화적, w-10 h-10)
- **텍스트**: textarea
- **사진**: 업로드 영역

#### 전문가 목록 (`masters/index`)
- **레이아웃**: 전문가 카드 그리드
- **카드**: 프로필 이미지 + 이름 + 별점 + 리뷰수 + 전문 분야

### 7.2 전문가 앱 (masters/)

#### 대시보드 (메인)
- **레이아웃**: 좌측 사이드바 + 우측 콘텐츠
- **통계 카드**: 4열 (매출, 평점, 진행중, 완료)
- **차트**: 월별 매출 바 차트 (Chart.js)
- **최근 요청**: 테이블 형태 (데스크톱), 카드 형태 (모바일)

#### 요청 관리 (`requests/`)
- **오픈 오더**: 수주 가능한 요청 리스트 (수락 버튼 포함)
- **내 요청**: 진행중인 요청 리스트 (상태 필터)
- **상세**: 고객 정보 + 현장 사진 + 견적 작성 + 시공 기록

#### 견적 작성 (`estimates/new, edit`)
- **레이아웃**: 항목별 입력 폼
- **항목 추가**: 동적 행 추가 (Stimulus)
- **합계**: 자동 계산, 실시간 업데이트
- **제출**: 고객에게 발송 CTA

#### 보험청구서 (`insurance_claims/`)
- **목록**: 상태별 필터 탭 + 리스트
- **작성/수정**: 상세 폼 + 파일 첨부
- **미리보기**: PDF 프리뷰
- **고객 발송**: 확인 모달 후 발송

#### 프로필/정산 (`profiles/, settlements/`)
- **프로필**: 전문가 정보 + 자격증 + 서비스 지역
- **정산**: 월별 정산 리스트 + 금액 요약 카드

### 7.3 관리자 앱 (admin/)

#### 대시보드
- **레이아웃**: 통계 카드 (4열) + 차트 (2열) + 최근 활동 테이블
- **색상**: 다크 teal 헤더 (`bg-primary-800`)
- **통계**: 총 체크수, 활성 마스터, 월 매출, 고객 만족도

#### 목록 페이지 (requests, masters, insurance_claims 등)
- **레이아웃**: 검색/필터 바 + 데이터 테이블
- **테이블**: 반응형 (모바일에서 카드 변환)
- **액션**: 상세보기, 승인/거절, 상태 변경

#### 상세 페이지
- **레이아웃**: 좌측 정보 패널 + 우측 액션 패널 (데스크톱)
- **모바일**: 단일 컬럼, 카드 나열

### 7.4 공통 페이지

#### 인증 (devise/)
- **로그인**: 중앙 정렬 카드, 소셜 로그인 버튼, 폼
- **회원가입**: 단계별 또는 단일 폼, 약관 동의
- **비밀번호 재설정**: 이메일 입력 폼

#### 정적 페이지 (pages/)
- **홈**: 랜딩페이지와 동일
- **이용방법**: 프로세스 단계 + 이미지
- **요금안내**: 가격표 카드 (3열)
- **FAQ**: 아코디언 리스트
- **리뷰**: 고객 리뷰 카드 그리드
- **이벤트**: 이벤트 카드 리스트

#### 메시지 (`messages/`)
- **목록**: 채팅방 리스트 (마지막 메시지 프리뷰)
- **채팅**: 카카오톡 스타일 말풍선 (내 메시지: primary, 상대: gray)

#### 알림 (`notifications/`)
- **목록**: 시간순 리스트, 읽음/안읽음 구분
- **각 항목**: 아이콘 + 제목 + 시간 + 읽음 표시

---

## 8. 인터랙션 & 애니메이션

### CSS 클래스 (application.css에 정의됨)
```css
/* 카드 호버 효과 */
.card-hover {
  transition: all 0.2s ease;
}
.card-hover:hover {
  transform: translateY(-2px);
}

/* 페이드 인 */
.fade-in {
  animation: fadeIn 0.3s ease-out;
}

/* 스켈레톤 로딩 */
.skeleton {
  background: linear-gradient(90deg, #f3f4f6, #e5e7eb, #f3f4f6);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
```

### Stimulus 컨트롤러 패턴
```html
<!-- 로딩 버튼 -->
<button data-controller="button-loading"
        data-action="click->button-loading#start"
        data-button-loading-text-value="처리중...">
  접수하기
</button>

<!-- 드롭다운 -->
<div data-controller="dropdown">
  <button data-action="click->dropdown#toggle">메뉴</button>
  <div data-dropdown-target="menu" class="hidden">...</div>
</div>

<!-- 파일 업로드 미리보기 -->
<div data-controller="upload-preview">
  <input type="file" data-action="change->upload-preview#preview">
  <div data-upload-preview-target="preview"></div>
</div>
```

---

## 9. 반응형 브레이크포인트

```
기본 (모바일):  0px~    → 단일 컬럼, 하단 탭 네비
sm (640px~):    640px~  → 약간의 여유 공간
md (768px~):    768px~  → 2열 레이아웃, 상단 네비로 전환
lg (1024px~):   1024px~ → 사이드바 레이아웃 (관리자/전문가)
```

### 주요 반응형 패턴
```html
<!-- 네비게이션 전환 -->
<nav class="md:hidden">하단 탭</nav>
<header class="hidden md:block">상단 네비</header>

<!-- 그리드 확장 -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">

<!-- 사이드바 + 콘텐츠 -->
<div class="lg:flex">
  <aside class="hidden lg:block lg:w-64">사이드바</aside>
  <main class="flex-1">콘텐츠</main>
</div>

<!-- 하단 패딩 조정 -->
<div class="pb-20 md:pb-8">
```

---

## 10. 아이콘 사용 가이드

### 아이콘 스타일
- **라인 아이콘** 기본 사용 (stroke, fill="none")
- **stroke-width**: 2 (기본), 2.5 (강조)
- **크기**: `w-4 h-4` (작은), `w-5 h-5` (기본), `w-6 h-6` (큰), `w-8 h-8` (아이콘 서클 내부)

### 자주 사용하는 아이콘 (Heroicons SVG)
```html
<!-- 플러스 (새 체크) -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/>

<!-- 화살표 (뒤로가기) -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>

<!-- 화살표 (앞으로) -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>

<!-- 위치 핀 -->
<path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>

<!-- 사람 (프로필) -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>

<!-- 문서 -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>

<!-- 클립보드 -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>

<!-- 벨 (알림) -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>

<!-- 카메라/비디오 -->
<path d="M2 6a2 2 0 012-2h6a2 2 0 012 2v8a2 2 0 01-2 2H4a2 2 0 01-2-2V6zM14.553 7.106A1 1 0 0014 8v4a1 1 0 00.553.894l2 1A1 1 0 0018 13V7a1 1 0 00-1.447-.894l-2 1z"/>

<!-- 체크마크 -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>

<!-- 홈 -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>

<!-- 설정/톱니바퀴 -->
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
```

---

## 11. 개발 시 체크리스트

새 페이지를 만들 때 반드시 확인:

### 구조
- [ ] `min-h-screen bg-gray-50 pb-20 md:pb-8` 페이지 래퍼 적용
- [ ] `max-w-4xl mx-auto px-4 py-6` 컨테이너 적용
- [ ] 모바일 하단 네비 렌더링 (`render "shared/customer_nav"`)
- [ ] 데스크톱 상단 네비 렌더링

### 스타일링
- [ ] 카드: `rounded-2xl border-2 border-gray-100` 사용
- [ ] 버튼: `rounded-2xl` 사용 (rounded-lg 금지)
- [ ] 색상: primary 색상 체계만 사용 (blue/indigo 금지)
- [ ] 폰트: Pretendard 기반 size 체계 준수
- [ ] 간격: 8px 그리드 (gap-2, gap-3, mb-6 등)

### UX
- [ ] 빈 상태(empty state) 처리
- [ ] 로딩 상태(skeleton) 처리
- [ ] 에러 상태 처리
- [ ] 뒤로가기 네비게이션
- [ ] 모바일 터치 영역 (최소 44px)

### 문화
- [ ] 모든 텍스트 한국어
- [ ] "신고" → "체크" 용어 준수
- [ ] 이모지 적절히 활용
- [ ] 이미지 사용 시 한국인/아시아인 모델

---

## 12. 공유 컴포넌트 (Shared Partials)

이미 구현된 컴포넌트들. 새 페이지에서 적극 활용할 것:

| 파일 | 용도 | 사용법 |
|---|---|---|
| `shared/card` | 기본 카드 래퍼 | `render "shared/card", title: "제목"` |
| `shared/customer_nav` | 고객 하단 네비 | `render "shared/customer_nav"` |
| `shared/empty_state` | 빈 상태 UI | `render "shared/empty_state", icon: "document", message: "...", action_path: ...` |
| `shared/flash_messages` | 토스트 알림 | `render "shared/flash_messages"` |
| `shared/form_errors` | 폼 에러 표시 | `render "shared/form_errors", resource: @resource` |
| `shared/list_item` | 리스트 항목 | `render "shared/list_item", title: "...", path: ...` |
| `shared/notifications_dropdown` | 알림 드롭다운 | `render "shared/notifications_dropdown"` |
| `shared/onboarding` | 온보딩 플로우 | `render "shared/onboarding"` |
| `shared/page_header` | 페이지 헤더 | `render "shared/page_header", title: "...", back_path: ...` |
| `shared/skeleton_card` | 스켈레톤 카드 | `render "shared/skeleton_card"` |
| `shared/skeleton_list` | 스켈레톤 리스트 | `render "shared/skeleton_list", count: 3` |
| `shared/status_badge` | 상태 뱃지 | `render "shared/status_badge", status: request.status` |
| `shared/status_timeline` | 상태 타임라인 | `render "shared/status_timeline", request_record: @request` |

---

## 13. 우선순위 (P0 → P1 → P2)

### P0 - 핵심 플로우 (먼저 완성)
- 고객 랜딩 ✅
- 고객 대시보드 ✅
- 체크 접수 위자드 ✅
- 로그인/회원가입
- 요청 상세
- 견적 상세

### P1 - 주요 기능
- 요청 목록
- 보험 신청 (목록/상세/작성)
- 결제 (체크아웃)
- 전문가 대시보드 ✅
- 전문가 요청 관리
- 전문가 견적 작성
- 메시지/채팅

### P2 - 부가 기능
- 프로필 (보기/수정)
- 설정
- 리뷰 작성
- 알림 목록
- 관리자 대시보드
- 관리자 목록/상세 페이지들
- 정적 페이지 (FAQ, 요금, 이용방법 등)
- 전문가 보험청구서
- 전문가 정산

---

**버전**: 2.0
**최종 업데이트**: 2026-03-09
**관련 파일**: `CLAUDE.md`, `tailwind.config.js`, `application.css`
