import { test, expect } from '@playwright/test';
import { e2eConfig } from '../e2e.config';

const { baseURL, smokeScenarios, testUser, masterUser } = e2eConfig;

// 로그인이 필요한 시나리오는 env 설정 여부에 따라 skip
const hasTestUser = !!(testUser.email && testUser.password);
const hasMasterUser = !!(masterUser.email && masterUser.password);

for (const scenario of smokeScenarios) {
  const needsTestUser =
    scenario.steps.some((s) => 'value' in s && (s.value as string).includes('{{testUser'));
  const needsMasterUser =
    scenario.steps.some((s) => 'value' in s && (s.value as string).includes('{{masterUser'));

  const shouldSkip = (needsTestUser && !hasTestUser) || (needsMasterUser && !hasMasterUser);

  test(scenario.name, async ({ page }) => {
    if (shouldSkip) {
      test.skip(true, '로그인 계정 env 미설정 — .env.e2e 에 E2E_USER_EMAIL 등 추가 필요');
      return;
    }

    let lastResponse: number | null = null;

    for (const step of scenario.steps) {
      if (step.action === 'goto') {
        const res = await page.goto(baseURL + (step.target as string), {
          waitUntil: 'domcontentloaded',
        });
        lastResponse = res?.status() ?? null;

      } else if (step.action === 'fill') {
        // {{testUser.email}} 같은 플레이스홀더를 실제 값으로 치환
        let value = (step as any).value as string;
        value = value
          .replace('{{testUser.email}}', testUser.email)
          .replace('{{testUser.password}}', testUser.password)
          .replace('{{masterUser.email}}', masterUser.email)
          .replace('{{masterUser.password}}', masterUser.password);
        await page.fill(step.target as string, value);

      } else if (step.action === 'click') {
        await page.click(step.target as string);
        await page.waitForLoadState('domcontentloaded');

      } else if (step.action === 'expectStatus') {
        // goto 직후 status 확인
        expect(lastResponse, `HTTP ${step.target} 기대, 실제: ${lastResponse}`).toBe(
          step.target as number
        );

      } else if (step.action === 'expectVisible') {
        await expect(page.locator(step.target as string).first()).toBeVisible({
          timeout: 10000,
        });

      } else if (step.action === 'expectUrl') {
        await page.waitForURL(`**${step.target as string}**`, { timeout: 10000 });
        expect(page.url()).toContain(step.target as string);
      }
    }
  });
}
