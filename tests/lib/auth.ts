import { Browser } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { e2eConfig } from '../e2e.config';

const STATE_FILE = path.join(__dirname, '../.auth/state.json');

export async function saveAuthState(browser: Browser) {
  if (!e2eConfig.auth.enabled) return;

  const ctx = await browser.newContext();
  const page = await ctx.newPage();

  await page.goto(e2eConfig.baseURL + e2eConfig.auth.loginUrl);
  await page.fill(e2eConfig.auth.emailSelector!, e2eConfig.auth.testEmail!);
  await page.fill(e2eConfig.auth.passwordSelector!, e2eConfig.auth.testPassword!);
  await page.click(e2eConfig.auth.submitSelector!);
  await page.waitForURL(`**${e2eConfig.auth.successIndicator}**`);

  const dir = path.dirname(STATE_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  await ctx.storageState({ path: STATE_FILE });
  await ctx.close();
}

export function getStorageState(): string | undefined {
  if (!e2eConfig.auth.enabled) return undefined;
  return fs.existsSync(STATE_FILE) ? STATE_FILE : undefined;
}
