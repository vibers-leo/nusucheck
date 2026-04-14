export const e2eConfig = {
  projectName: 'nusucheck',
  baseURL: process.env.E2E_BASE_URL || 'http://localhost:3000',

  auth: {
    enabled: true,
    loginUrl: '/users/sign_in',
    testEmail: process.env.E2E_USER_EMAIL || '',
    testPassword: process.env.E2E_USER_PASSWORD || '',
    emailSelector: '#user_email',
    passwordSelector: '#user_password',
    submitSelector: 'button[type="submit"]',
    successIndicator: '/customers/dashboard',
  },

  // 고객 계정
  testUser: {
    email: process.env.E2E_USER_EMAIL || '',
    password: process.env.E2E_USER_PASSWORD || '',
  },
  // 마스터(전문가) 계정
  masterUser: {
    email: process.env.E2E_MASTER_EMAIL || '',
    password: process.env.E2E_MASTER_PASSWORD || '',
  },
  // 관리자 계정
  adminUser: {
    email: process.env.E2E_ADMIN_EMAIL || '',
    password: process.env.E2E_ADMIN_PASSWORD || '',
  },

  crawl: {
    maxDepth: 3,
    maxPages: 50,
    startUrls: [
      '/',
      '/about',
      '/pricing',
      '/how-it-works',
      '/faq',
      '/reviews',
      '/terms',
      '/privacy',
      '/refund',
      '/expert',
      '/users/sign_in',
      '/users/sign_up',
    ],
    includePatterns: ['^/'],
    excludePatterns: [
      '/rails/',
      '/cable',
      '/sidekiq',
      '/admin/',
      '/api/',
      '\\.json$',
      'sign_out',
      'logout',
      '/edit$',
      '/destroy',
      'pg/webhooks',
    ],
  },

  click: {
    selectors: [
      'button:not([type="submit"])',
      'a[href^="/"]',
      '[role="button"]',
    ],
    skipSelectors: [
      '[data-destructive]',
      '[data-e2e-skip]',
      'button[type="submit"]:not([data-e2e-safe])',
      'a[href*="sign_out"]',
      'a[href*="logout"]',
      'a[data-turbo-method="delete"]',
    ],
    skipTextPatterns: [
      /삭제/,
      /탈퇴/,
      /결제/,
      /로그아웃/,
      /취소/,
      /환불/,
      /승인/,
      /에스크로/,
      /견적 확정/,
    ],
  },

  // smoke 시나리오 — 실제 라우트/뷰 기준
  smokeScenarios: [
    {
      name: '홈 페이지 로드',
      steps: [
        { action: 'goto', target: '/' },
        { action: 'expectStatus', target: 200 },
        { action: 'expectVisible', target: 'text=누수 전문가' },
      ],
    },
    {
      name: '로그인 페이지 — 폼 필드 존재',
      steps: [
        { action: 'goto', target: '/users/sign_in' },
        { action: 'expectVisible', target: '#user_email' },
        { action: 'expectVisible', target: '#user_password' },
      ],
    },
    {
      name: '회원가입 페이지 — 폼 필드 존재',
      steps: [
        { action: 'goto', target: '/users/sign_up' },
        { action: 'expectVisible', target: '#user_email' },
        { action: 'expectVisible', target: '#user_password' },
      ],
    },
    {
      name: '서비스 소개 페이지 200',
      steps: [
        { action: 'goto', target: '/about' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: '요금 안내 페이지 200',
      steps: [
        { action: 'goto', target: '/pricing' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: '이용 방법 페이지 200',
      steps: [
        { action: 'goto', target: '/how-it-works' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: 'FAQ 페이지 200',
      steps: [
        { action: 'goto', target: '/faq' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: '이용약관 페이지 200',
      steps: [
        { action: 'goto', target: '/terms' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: '개인정보처리방침 페이지 200',
      steps: [
        { action: 'goto', target: '/privacy' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: '취소·환불정책 페이지 200',
      steps: [
        { action: 'goto', target: '/refund' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: '전문가 랜딩 페이지 200',
      steps: [
        { action: 'goto', target: '/expert' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: 'AI 사전점검 페이지 200',
      steps: [
        { action: 'goto', target: '/leak_inspections/new' },
        { action: 'expectStatus', target: 200 },
      ],
    },
    {
      name: '고객 로그인 → 대시보드 렌더',
      steps: [
        { action: 'goto', target: '/users/sign_in' },
        { action: 'fill', target: '#user_email', value: '{{testUser.email}}' },
        { action: 'fill', target: '#user_password', value: '{{testUser.password}}' },
        { action: 'click', target: 'button[type="submit"]' },
        { action: 'expectUrl', target: '/customers/' },
      ],
    },
    {
      name: '마스터 로그인 → 체크 목록 렌더',
      steps: [
        { action: 'goto', target: '/users/sign_in' },
        { action: 'fill', target: '#user_email', value: '{{masterUser.email}}' },
        { action: 'fill', target: '#user_password', value: '{{masterUser.password}}' },
        { action: 'click', target: 'button[type="submit"]' },
        { action: 'expectUrl', target: '/masters/' },
      ],
    },
  ],

  ignoreErrors: {
    console: [
      /Warning: React does not recognize/,
      /Download the React DevTools/,
      /ActionCable/,
      /Failed to load resource.*cable/,
    ],
    network: [
      { url: /google-analytics/, status: [0, 404] },
      { url: /googletagmanager/, status: [0, 404] },
      { url: /pagead/, status: [0, 404] },
      { url: /hotjar/, status: [0, 404] },
    ],
  },

  // 파괴적 액션 셀렉터 (crawl-clickable 에서 skip 처리)
  destructiveSelectors: [
    '[data-destructive]',
    'a:has-text("삭제")',
    'button:has-text("삭제")',
    'button:has-text("승인")',
    'button:has-text("결제")',
    'button:has-text("에스크로")',
    'a[data-turbo-method="delete"]',
  ],

  hitExternalAPIs: false,
};
