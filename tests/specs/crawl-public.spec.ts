import { test, expect } from '@playwright/test';
import { crawl } from '../lib/crawler';
import { generateReport } from '../lib/reporter';
import { e2eConfig } from '../e2e.config';

test('공개 페이지 크롤링', async ({ page }) => {
  const results = await crawl(page, e2eConfig);

  const failures = results.filter((r) => r.status >= 400 || r.status === -1);
  generateReport(results);

  expect(
    failures,
    `HTTP 에러 페이지: ${failures.map((r) => `${r.url} (${r.status})`).join(', ')}`
  ).toHaveLength(0);
});
