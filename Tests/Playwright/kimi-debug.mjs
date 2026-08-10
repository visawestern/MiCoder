import { chromium } from 'playwright';

async function debug() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(8000);
  
  // Click new chat
  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);
  
  // Get ALL buttons
  const buttons = await page.locator('button').all();
  console.log(`Found ${buttons.length} buttons:`);
  for (const btn of buttons.slice(0, 20)) {
    const text = await btn.textContent().catch(() => '');
    const aria = await btn.getAttribute('aria-label') || '';
    const cls = await btn.getAttribute('class') || '';
    console.log(`  "${text?.trim().substring(0, 30)}" aria="${aria}" cls="${cls?.substring(0, 50)}"`);
  }
  
  // Type in input
  const input = page.locator('textarea, div[contenteditable="true"]').first();
  await input.fill('test');
  await page.waitForTimeout(2000);
  
  // Check buttons again after typing
  console.log('\nAfter typing:');
  const buttons2 = await page.locator('button').all();
  for (const btn of buttons2.slice(0, 20)) {
    const text = await btn.textContent().catch(() => '');
    const aria = await btn.getAttribute('aria-label') || '';
    const cls = await btn.getAttribute('class') || '';
    const visible = await btn.isVisible();
    if (visible) console.log(`  VISIBLE: "${text?.trim().substring(0, 30)}" aria="${aria}" cls="${cls?.substring(0, 50)}"`);
  }
  
  await browser.close();
}
debug().catch(console.error);
