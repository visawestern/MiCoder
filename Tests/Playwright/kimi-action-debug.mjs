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
  const input = page.locator('.chat-input-editor').first();
  await input.fill('привет');
  await page.waitForTimeout(3000);

  // Check the action area for send button
  console.log('=== Action Area After Typing ===');
  const actionArea = await page.evaluate(() => {
    const action = document.querySelector('.chat-editor-action');
    return action ? action.outerHTML.substring(0, 3000) : 'No action area';
  });
  console.log(actionArea);

  // Look for send button specifically
  console.log('\n=== Send Button Search ===');
  const sendBtn = await page.evaluate(() => {
    const buttons = document.querySelectorAll('button, [role="button"], .icon-button');
    const results = [];
    for (const btn of buttons) {
      if (!btn.isVisible()) continue;
      const rect = btn.getBoundingClientRect();
      if (rect.y < 500 || rect.y > 800) continue;
      const text = btn.textContent?.trim();
      const aria = btn.getAttribute('aria-label') || '';
      const cls = btn.className?.toString()?.substring(0, 50) || '';
      results.push({ text: text?.substring(0, 30), aria, cls, y: rect.y, x: rect.x });
    }
    return results;
  });
  sendBtn.forEach(b => console.log(`  "${b.text}" aria="${b.aria}" cls="${b.cls}" x=${b.x} y=${b.y}`));

  await browser.close();
}
debug().catch(console.error);
