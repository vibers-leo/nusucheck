import { Page } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { e2eConfig } from '../e2e.config';

export interface PageResult {
  url: string;
  status: number;
  consoleErrors: string[];
  networkErrors: { url: string; status: number }[];
  loadTime: number;
}

export async function crawl(page: Page, config: typeof e2eConfig): Promise<PageResult[]> {
  const visited = new Set<string>();
  const queue: string[] = [...config.crawl.startUrls];
  const results: PageResult[] = [];

  while (queue.length > 0 && visited.size < config.crawl.maxPages) {
    const urlPath = queue.shift()!;
    if (visited.has(urlPath)) continue;
    visited.add(urlPath);

    const consoleErrors: string[] = [];
    const networkErrors: { url: string; status: number }[] = [];

    const consoleHandler = (msg: any) => {
      if (msg.type() === 'error') {
        const text = msg.text();
        const ignored = config.ignoreErrors.console.some((p) => p.test(text));
        if (!ignored) consoleErrors.push(text);
      }
    };

    const responseHandler = (res: any) => {
      if (res.status() >= 400) {
        const resUrl = res.url();
        const ignored = config.ignoreErrors.network.some(
          (p) => p.url.test(resUrl) && p.status.includes(res.status())
        );
        if (!ignored) networkErrors.push({ url: resUrl, status: res.status() });
      }
    };

    page.on('console', consoleHandler);
    page.on('response', responseHandler);

    const start = Date.now();
    let status = 0;
    try {
      const response = await page.goto(config.baseURL + urlPath, {
        waitUntil: 'domcontentloaded',
        timeout: 15000,
      });
      status = response?.status() ?? 0;
    } catch (_) {
      status = -1;
    }
    const loadTime = Date.now() - start;

    results.push({ url: urlPath, status, consoleErrors, networkErrors, loadTime });

    // 내부 링크 수집
    if (visited.size < config.crawl.maxPages && status < 400) {
      try {
        const links = await page.$$eval('a[href]', (els) =>
          els.map((el) => el.getAttribute('href')).filter(Boolean)
        );
        for (const link of links as string[]) {
          if (!link) continue;
          const included = config.crawl.includePatterns.some((p) => new RegExp(p).test(link));
          const excluded = config.crawl.excludePatterns.some((p) => new RegExp(p).test(link));
          if (included && !excluded && !visited.has(link) && !queue.includes(link)) {
            queue.push(link);
          }
        }
      } catch (_) {}
    }

    page.removeAllListeners('console');
    page.removeAllListeners('response');
  }

  // 결과 저장
  const outDir = path.join(process.cwd(), 'test-results');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'visited.json'), JSON.stringify(results, null, 2));

  return results;
}
