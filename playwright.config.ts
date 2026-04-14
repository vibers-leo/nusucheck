import { defineConfig } from '@playwright/test';
import { e2eConfig } from './tests/e2e.config';

export default defineConfig({
  testDir: './tests/specs',
  timeout: 30000,
  retries: 1,
  workers: 1,
  reporter: [['html', { outputFolder: 'playwright-report' }], ['list']],
  use: {
    baseURL: e2eConfig.baseURL,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },
});
