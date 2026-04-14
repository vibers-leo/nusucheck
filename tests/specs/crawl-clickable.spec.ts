import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { clickAll } from '../lib/clicker';
import { e2eConfig } from '../e2e.config';

test('클릭 가능 요소 자동 클릭', async ({ page }) => {
  const visitedFile = path.join(process.cwd(), 'test-results/visited.json');

  let pages: { url: string }[] = e2eConfig.crawl.startUrls.map((u) => ({ url: u }));
  if (fs.existsSync(visitedFile)) {
    pages = JSON.parse(fs.readFileSync(visitedFile, 'utf-8'));
  }

  const allErrors: string[] = [];

  for (const { url } of pages.slice(0, 10)) {
    // 최대 10페이지
    await page.goto(e2eConfig.baseURL + url, { waitUntil: 'domcontentloaded' });
    const results = await clickAll(page, e2eConfig);
    const errors = results.filter((r) => r.outcome === 'error');
    errors.forEach((e) => allErrors.push(`[${url}] ${e.element}: ${e.error}`));
  }

  expect(allErrors, `클릭 에러:\n${allErrors.join('\n')}`).toHaveLength(0);
});
