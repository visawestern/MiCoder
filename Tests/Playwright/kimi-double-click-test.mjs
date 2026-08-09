import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI DOUBLE CLICK ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first().click();
  await page.waitForTimeout(5000);
  
  const modelBtn = page.locator('div.current-model').first();
  
  console.log('1. ПРОБУЮ ДВОЙНОЙ КЛИК:');
  await modelBtn.dblclick();
  await page.waitForTimeout(2000);
  
  // Ищем появившиеся элементы
  const dropdownSelectors = [
    '[class*="model"][class*="list"]',
    '[class*="model"][class*="menu"]',
    '[class*="model"][class*="panel"]',
    '[role="listbox"]',
    '[role="menu"]',
  ];
  
  for (const sel of dropdownSelectors) {
    const count = await page.locator(sel).count();
    if (count > 0) {
      const visible = await page.locator(sel).first().isVisible();
      if (visible) {
        console.log(`   ✅ ${sel}: ${count} elements`);
        const text = await page.locator(sel).first().textContent();
        console.log(`      text: "${text?.substring(0, 200)}"`);
      }
    }
  }
  
  // Если не сработало - пробуем клик на стрелку
  console.log('\n2. ПРОБУЮ КЛИК НА СТРЕЛКУ (svg.arrow):');
  const arrow = page.locator('div.current-model svg.arrow').first();
  const arrowVisible = await arrow.isVisible();
  console.log(`   arrow visible: ${arrowVisible}`);
  if (arrowVisible) {
    await arrow.click();
    await page.waitForTimeout(2000);
    
    for (const sel of dropdownSelectors) {
      const count = await page.locator(sel).count();
      if (count > 0) {
        const visible = await page.locator(sel).first().isVisible();
        if (visible) {
          console.log(`   ✅ ${sel}: ${count} elements`);
          const text = await page.locator(sel).first().textContent();
          console.log(`      text: "${text?.substring(0, 200)}"`);
        }
      }
    }
  }
  
  console.log('\n3. ИТОГОВЫЙ HTML (фрагмент с model):');
  const bodyHtml = await page.locator('body').innerHTML();
  const modelIdx = bodyHtml.indexOf('model-name');
  if (modelIdx > -1) {
    console.log(bodyHtml.substring(modelIdx - 50, modelIdx + 1000));
  }
  
  await browser.close();
}

test().catch(console.error);
