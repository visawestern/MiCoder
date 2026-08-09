import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== CHATGPT ALT APPROACH ===\n');
  await page.goto('https://chatgpt.com/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);
  
  console.log('1. КЛИК НА КНОПКУ МОДЕЛИ (button[data-testid*="model"]):');
  const modelBtn = page.locator('button[data-testid*="model"]').first();
  const dataTestId = await modelBtn.getAttribute('data-testid');
  console.log(`   data-testid: "${dataTestId}"`);
  
  await modelBtn.click();
  await page.waitForTimeout(2000);
  
  // Ищем появившиеся popup/menu
  console.log('\n2. ПОИСК POPUP/MENU:');
  const popups = await page.locator('[role="menu"], [role="dialog"], [role="listbox"], [class*="popover"], [class*="dropdown"], [class*="popup"]').all();
  for (const popup of popups.slice(0, 5)) {
    const visible = await popup.isVisible();
    if (visible) {
      const text = await popup.textContent();
      console.log(`   ✅ visible popup: "${text?.substring(0, 100)}"`);
    }
  }
  
  console.log('\n3. ПОИСК ПО ТЕКСТУ "GPT-4o" ИЛИ "o1":');
  const modelTexts = ['GPT-4o', 'GPT-4', 'o1', 'o3', 'mini', 'turbo'];
  for (const mt of modelTexts) {
    const count = await page.locator('*').filter({ hasText: mt }).count();
    if (count > 0) {
      const visible = await page.locator('*').filter({ hasText: mt }).first().isVisible();
      console.log(`   "${mt}": ${count} elements, visible: ${visible}`);
    }
  }
  
  await page.screenshot({ path: '/tmp/chatgpt-alt.png' });
  console.log('\n📸 /tmp/chatgpt-alt.png');
  
  await browser.close();
}

test().catch(console.error);
