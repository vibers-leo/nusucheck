import * as fs from 'fs';
import * as path from 'path';
import { PageResult } from './crawler';
import { e2eConfig } from '../e2e.config';

export function generateReport(
  results: PageResult[],
  opts: { screenshotDir?: string } = {}
) {
  const date = new Date().toISOString().slice(0, 10);
  const outDir = path.join(process.env.HOME || '~', 'Desktop/macminim4/qa-reports');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

  const failures = results.filter((r) => r.status >= 400 || r.status === -1);
  const consoleErrorPages = results.filter((r) => r.consoleErrors.length > 0);
  const networkErrorPages = results.filter((r) => r.networkErrors.length > 0);
  const avgLoad = Math.round(
    results.reduce((s, r) => s + r.loadTime, 0) / (results.length || 1)
  );

  const lines: string[] = [
    `# ${e2eConfig.projectName} E2E 테스트 리포트`,
    `> 생성일: ${date} | baseURL: ${e2eConfig.baseURL}`,
    '',
    '## 요약',
    `| 항목 | 값 |`,
    `|------|-----|`,
    `| 총 페이지 | ${results.length} |`,
    `| HTTP 에러 | ${failures.length} |`,
    `| 콘솔 에러 페이지 | ${consoleErrorPages.length} |`,
    `| 네트워크 에러 페이지 | ${networkErrorPages.length} |`,
    `| 평균 로드 타임 | ${avgLoad}ms |`,
    '',
  ];

  if (failures.length > 0) {
    lines.push('## HTTP 에러 페이지');
    for (const r of failures) {
      lines.push(`- \`${r.url}\` → HTTP ${r.status}`);
    }
    lines.push('');
  }

  if (consoleErrorPages.length > 0) {
    lines.push('## 콘솔 에러');
    for (const r of consoleErrorPages) {
      lines.push(`### ${r.url}`);
      r.consoleErrors.forEach((e) => lines.push(`- ${e}`));
    }
    lines.push('');
  }

  if (networkErrorPages.length > 0) {
    lines.push('## 네트워크 에러');
    for (const r of networkErrorPages) {
      lines.push(`### ${r.url}`);
      r.networkErrors.forEach((e) => lines.push(`- \`${e.url}\` → ${e.status}`));
    }
    lines.push('');
  }

  lines.push('## 권장 조치');
  if (failures.length === 0 && consoleErrorPages.length === 0) {
    lines.push('발견된 에러 없음.');
  } else {
    if (failures.length > 0) lines.push(`- HTTP 에러 ${failures.length}개 페이지 수정 필요`);
    if (consoleErrorPages.length > 0)
      lines.push(`- 콘솔 에러 ${consoleErrorPages.length}개 페이지 확인 필요`);
  }

  const filename = `${date}-${e2eConfig.projectName}-e2e.md`;
  const fullPath = path.join(outDir, filename);
  fs.writeFileSync(fullPath, lines.join('\n'));
  console.log(`\nQA 리포트 생성: ${fullPath}`);
  return fullPath;
}
