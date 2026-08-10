import { chromium } from 'playwright';

async function debug() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(8000);

  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);

  // Get the chat input area structure
  console.log('=== Chat Input Area ===');
  const inputArea = await page.evaluate(() => {
    const textarea = document.querySelector('textarea, div[contenteditable="true"]');
    if (!textarea) return 'No input found';
    let parent = textarea.parentElement;
    let html = '';
    for (let i = 0; i < 5 && parent; i++) {
      html = parent.outerHTML.substring(0, 2000);
      parent = parent.parentElement;
    }
    return html;
  });
  console.log(inputArea);
  
  // Type and check for send button
  const input = page.locator('textarea, div[contenteditable="true"]').first();
  await input.fill('привет');
  await page.waitForTimeout(3000);
  
  console.log('\n=== After typing ===');
  const afterType = await page.evaluate(() => {
    const textarea = document.querySelector('textarea, div[contenteditable="true"]');
    if (!textarea) return 'No input';
    let parent = textarea.closest('div, section, form');
    return parent ? parent.outerHTML.substring(0, 2000) : 'No parent';
  });
  console.log(afterType);

  await browser.close();
}
debug().catch(console.error);
