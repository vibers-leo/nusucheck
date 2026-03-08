# 누수체크 디자인 시스템 - 빠른 참조

**이 문서는 빠른 구현을 위한 치트시트입니다. 상세 내용은 `DESIGN_REFERENCE_ANALYSIS.md`를 참고하세요.**

---

## 색상 팔레트

### 사용 가능한 색상
```css
/* 배경 */
#1a1b1e  /* 주배경 */
#292a2f  /* 카드/섹션 */
#34363c  /* 경계선 */

/* 텍스트 */
#ffffff  /* 주 텍스트 */
#cbcdd2  /* 보조 텍스트 */
#a8abb4  /* 약한 텍스트 */

/* 강조 & 상태 */
#b1b0ff  /* PRIMARY - 보라색 (AI) */
#3498db  /* INFO - 파랑 (진행) */
#07bc0c  /* SUCCESS - 초록 (완료) */
#e74c3c  /* ERROR - 빨강 (경고) */
#f1c40f  /* WARNING - 노랑 (대기) */
```

### 상태별 사용
| 상태 | 배경 | 텍스트 | 용도 |
|------|------|--------|------|
| 대기 | #f1c40f | #1a1b1e | 마스터 배정 대기 |
| 진행 | #3498db | #ffffff | 체크 진행 중 |
| 완료 | #07bc0c | #ffffff | 체크 완료 |
| 경고 | #e74c3c | #ffffff | 누수 심각/오류 |
| 비활성 | #a8abb4 | #1a1b1e | 사용 불가 |

---

## 타이포그래피

### 폰트 스택
```css
font-family: Pretendard, SUIT, 'SUIT Variable', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
```

### 크기 및 무게
```
Display  24-36px  weight: 600
H1       24px     weight: 600
H2       20px     weight: 600
H3       18px     weight: 400
Body     16px     weight: 400
Body-SM  14px     weight: 400
Caption  13px     weight: 400
Label    12px     weight: 400
```

### 라인 높이
```
제목:    1.4
본문:    1.5-1.6
```

---

## 공간 시스템 (8px 그리드)

```
4px  → xs (미세)
8px  → sm (소)
12px → md (중)
16px → lg (표준)
20px → xl (크)
24px → 2xl (매우 큼)
32px → 3xl (최대)
```

### 실제 적용
- 카드 패딩: **16px**
- 섹션 패딩: **20px**
- 버튼 패딩: **12px 16px**
- 컴포넌트 갭: **10-13px**
- 섹션 갭: **24px**

---

## 모양 (Shape)

```
버튼, 입력    border-radius: 10px
카드         border-radius: 12px
모달         border-radius: 16px
아바타/프로필  border-radius: 999px (원형)
```

---

## 그림자 (Shadows)

```css
/* 카드 기본 */
box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);

/* 카드 호버 */
box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);

/* 모달 */
box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
```

---

## 자주 사용되는 클래스 (Tailwind)

### 배경
```html
<!-- 메인 배경 -->
<div class="bg-dark-bg">

<!-- 카드/섹션 -->
<div class="bg-dark-card">

<!-- 강조 버튼 -->
<button class="bg-primary text-dark-bg">
```

### 텍스트
```html
<!-- 주 텍스트 -->
<p class="text-white">

<!-- 보조 텍스트 -->
<p class="text-gray-400">

<!-- 약한 텍스트 -->
<p class="text-gray-500">
```

### 상태
```html
<!-- 성공 배지 -->
<span class="bg-green-500 text-white">완료</span>

<!-- 경고 배지 -->
<span class="bg-red-500 text-white">경고</span>

<!-- 정보 배지 -->
<span class="bg-blue-500 text-white">진행중</span>

<!-- 대기 배지 -->
<span class="bg-yellow-500 text-dark-bg">대기중</span>
```

### 공간
```html
<!-- 패딩 -->
<div class="p-lg">        <!-- 16px -->
<div class="p-xl">        <!-- 20px -->

<!-- 마진 -->
<div class="mb-lg">       <!-- 16px margin-bottom -->
<div class="mt-2xl">      <!-- 24px margin-top -->

<!-- 갭 (flex/grid) -->
<div class="gap-md">      <!-- 12px gap -->
<div class="gap-lg">      <!-- 16px gap -->
```

### 모양
```html
<!-- 버튼/입력 -->
<button class="rounded-sm">        <!-- 10px -->

<!-- 카드 -->
<div class="rounded-md">           <!-- 12px -->

<!-- 모달 -->
<div class="rounded-lg">           <!-- 16px -->

<!-- 아바타 -->
<img class="rounded-full">         <!-- 999px -->
```

---

## 컴포넌트 패턴

### 버튼 (Primary)
```html
<button class="bg-primary text-dark-bg px-lg py-sm rounded-sm font-semibold">
  빠른 체크 신청
</button>
```

### 버튼 (Secondary)
```html
<button class="bg-dark-card text-white px-lg py-sm rounded-sm border border-gray-700">
  취소
</button>
```

### 카드
```html
<div class="bg-dark-card rounded-md p-lg">
  <h3 class="text-h2 text-white mb-md">제목</h3>
  <p class="text-body text-gray-400">설명 텍스트</p>
</div>
```

### 상태 배지
```html
<span class="px-md py-sm rounded-sm text-label font-semibold">
  진행중
</span>
<!-- bg-color는 상태에 따라 추가 -->
```

### 입력 필드
```html
<input class="bg-dark-bg text-white border border-gray-700 rounded-sm px-lg py-md placeholder-gray-500">
```

### 네비게이션 탭
```html
<div class="fixed bottom-0 left-0 right-0 bg-dark-card flex justify-around items-center h-16">
  <button class="text-primary">홈</button>
  <button class="text-gray-500">진행중</button>
  <button class="text-gray-500">완료</button>
  <button class="text-gray-500">검색</button>
  <button class="text-gray-500">마이페이지</button>
</div>
```

---

## 자주 하는 실수

### ❌ 하지 말아야 할 것
1. 다른 색상 사용 → 정의된 팔레트만 사용
2. 일관되지 않은 패딩 → 항상 8px 배수 사용
3. 제목 크기 추정 → 정의된 크기 정확히 사용
4. 밝은 배경 텍스트 → 다크 배경 필수
5. 상태 구분 없음 → 항상 색상 코드 사용

### ✅ 해야 할 것
1. 정의된 색상만 사용
2. 일관된 공간 시스템 적용
3. 타이포그래피 스케일 정확히 적용
4. 다크 배경 + 밝은 텍스트
5. 상태별 색상 코딩
6. 카드 기반 레이아웃
7. 하단 탭 네비게이션

---

## 구현 체크리스트

### 기본 설정
- [ ] Tailwind CSS colors 업데이트
- [ ] 폰트 추가 (Pretendard, SUIT)
- [ ] CSS 변수 정의
- [ ] 공간 시스템 설정

### 컴포넌트
- [ ] 버튼 (primary, secondary)
- [ ] 카드
- [ ] 입력 필드
- [ ] 배지/태그
- [ ] 모달
- [ ] 네비게이션

### 페이지
- [ ] 홈 (고객)
- [ ] 체크 상세
- [ ] 마이페이지
- [ ] 검색
- [ ] 마스터 프로필

### 통합
- [ ] 실시간 알림
- [ ] 상태 업데이트
- [ ] 애니메이션
- [ ] 반응형 테스트

---

## Tailwind Config 샘플

```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        'dark-bg': '#1a1b1e',
        'dark-card': '#292a2f',
        'dark-border': '#34363c',
        'text-primary': '#ffffff',
        'text-secondary': '#cbcdd2',
        'primary': '#b1b0ff',
        'success': '#07bc0c',
        'error': '#e74c3c',
        'warning': '#f1c40f',
        'info': '#3498db',
      },
      fontSize: {
        'display': ['36px', { lineHeight: '46px', fontWeight: '600' }],
        'h1': ['24px', { lineHeight: '30px', fontWeight: '600' }],
        'h2': ['20px', { lineHeight: '26px', fontWeight: '600' }],
        'body': ['16px', { lineHeight: '24px' }],
        'caption': ['13px', { lineHeight: '18px' }],
        'label': ['12px', { lineHeight: '16px' }],
      },
      spacing: {
        'xs': '4px',
        'sm': '8px',
        'md': '12px',
        'lg': '16px',
        'xl': '20px',
        '2xl': '24px',
        '3xl': '32px',
      },
      borderRadius: {
        'sm': '10px',
        'md': '12px',
        'lg': '16px',
      },
    }
  }
}
```

---

## 문의 사항

더 자세한 내용은 `DESIGN_REFERENCE_ANALYSIS.md`를 참고하세요.

마지막 업데이트: 2026-03-09
