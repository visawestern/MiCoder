import { chromium } from 'playwright';

async function debug() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(8000);

  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);

  // Type in input
  const input = page.locator('textarea, div[contenteditable="true"]').first();
  await input.fill('привет');
  await page.waitForTimeout(3000);

  // Get ALL elements that could be send buttons
  console.log('Looking for send button after typing...');

  // Check for arrow/send icons
  const allBtns = await page.locator('button, [role="button"]').all();
  for (const btn of allBtns) {
    const visible = await btn.isVisible();
    if (!visible) continue;
    const text = await btn.textContent().catch(() => '');
    const aria = await btn.getAttribute('aria-label') || '';
    const cls = await btn.getAttribute('class') || '';
    const rect = await btn.boundingBox();
    if (rect && rect.y > 500) {
      console.log(`  btn: "${text?.trim().substring(0, 20)}" aria="${aria}" cls="${cls?.substring(0, 40)}" y=${rect.y}`);
    }
  }

  // Also check for SVG icons that might be send buttons
  const svgs = await page.locator('svg').all();
  for (const svg of svgs.slice(0, 15)) {
    const visible = await svg.isVisible();
    if (!visible) continue;
    const parent = svg.locator('..');
    const parentTag = await parent.evaluate(el => el.tagName).catch(() => '?');
    const rect = await svg.boundingBox();
    if (rect && rect.y > 500) {
      console.log(`  svg parent=${parentTag} y=${rect.y}`);
    }
  }

  await browser.close();
}
debug().catch(console.error);
