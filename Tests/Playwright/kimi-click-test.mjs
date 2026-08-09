import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI CLICK MODEL BUTTON ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first().click();
  await page.waitForTimeout(5000);
  
  console.log('1. КЛИК НА div.current-model');
  const modelBtn = page.locator('div.current-model').first();
  
  // Перед кликом - скриншот
  await page.screenshot({ path: '/tmp/kimi-before-click.png' });
  
  await modelBtn.click();
  await page.waitForTimeout(2000);
  
  // После клика - скриншот
  await page.screenshot({ path: '/tmp/kimi-after-click.png' });
  
  console.log('2. ПОИСК НОВЫХ ЭЛЕМЕНТОВ ПОСЛЕ КЛИКА:');
  const newSelectors = [
    '[class*="model-list"]',
    '[class*="model-popup"]',
    '[class*="model-menu"]',
    '[class*="model-dropdown"]',
    '[class*="picker"]',
    '[class*="option"]',
    '[role="listbox"]',
    '[role="option"]',
    '[class*="popup"]',
    '[class*="modal"]',
    '[class*="dialog"]',
    '[class*="overlay"]',
  ];
  
  for (const sel of newSelectors) {
    const count = await page.locator(sel).count();
    if (count > 0) {
      const visible = await page.locator(sel).first().isVisible();
      console.log(`   ${sel}: ${count} elements, visible: ${visible}`);
      if (visible) {
        const text = await page.locator(sel).first().textContent();
        console.log(`      text: "${text?.substring(0, 100)}"`);
      }
    }
  }
  
  console.log('\n3. ПОЛНЫЙ HTML (первые 2000 символов):');
  const bodyHtml = await page.locator('body').innerHTML();
  // Ищем часть с моделями
  const modelIdx = bodyHtml.indexOf('current-model');
  if (modelIdx > -1) {
    console.log(bodyHtml.substring(modelIdx, modelIdx + 1500));
  }
  
  await browser.close();
}

test().catch(console.error);
