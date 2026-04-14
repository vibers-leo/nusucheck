import { Page } from '@playwright/test';
import { e2eConfig } from '../e2e.config';

export interface ClickResult {
  pageUrl: string;
  element: string;
  outcome: 'ok' | 'error' | 'skipped' | 'navigated';
  error?: string;
}

export async function clickAll(page: Page, config: typeof e2eConfig): Promise<ClickResult[]> {
  const results: ClickResult[] = [];
  const pageUrl = page.url();

  for (const selector of config.click.selectors) {
    let elements: any[] = [];
    try {
      elements = await page.$$(selector);
    } catch (_) {
      continue;
    }

    for (const el of elements) {
      let text = '';
      try {
        text = (await el.innerText()).trim();
      } catch (_) {}

      // skipTextPatterns 체크
      const skipByText = config.click.skipTextPatterns.some((p) => p.test(text));
      if (skipByText) {
        results.push({ pageUrl, element: `${selector}: ${text}`, outcome: 'skipped' });
        continue;
      }

      // skipSelectors 체크 — data 속성 기반으로 단순화
      let skipBySelector = false;
      try {
        const dataDestructive = await el.getAttribute('data-destructive');
        const dataSkip = await el.getAttribute('data-e2e-skip');
        const href = await el.getAttribute('href');
        if (
          dataDestructive !== null ||
          dataSkip !== null ||
          (href && (href.includes('logout') || href.includes('signout')))
        ) {
          skipBySelector = true;
        }
      } catch (_) {}

      if (skipBySelector) {
        results.push({ pageUrl, element: `${selector}: ${text}`, outcome: 'skipped' });
        continue;
      }

      const beforeUrl = page.url();
      try {
        await el.click({ timeout: 3000 });
        await page.waitForTimeout(500);
        const afterUrl = page.url();
        if (afterUrl !== beforeUrl) {
          results.push({ pageUrl, element: `${selector}: ${text}`, outcome: 'navigated' });
          await page.goto(beforeUrl, { waitUntil: 'domcontentloaded' });
        } else {
          results.push({ pageUrl, element: `${selector}: ${text}`, outcome: 'ok' });
        }
      } catch (e: any) {
        results.push({
          pageUrl,
          element: `${selector}: ${text}`,
          outcome: 'error',
          error: e.message,
        });
      }
    }
  }

  return results;
}
