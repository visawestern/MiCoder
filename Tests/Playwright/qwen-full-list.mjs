import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== QWEN FULL MODEL LIST ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);
  
  await page.locator('button').filter({ hasText: 'Начать' }).first().click();
  await page.waitForTimeout(5000);
  
  await page.locator('[class*="model-selector-text"]').first().click();
  await page.waitForTimeout(3000);
  
  console.log('МОДЕЛИ:');
  const models = await page.evaluate(() => {
    const items = document.querySelectorAll('[class*="model-item-name"]');
    return Array.from(items).map(el => el.textContent.trim());
  });
  
  console.log(`Найдено: ${models.length}`);
  models.forEach((m, i) => console.log(`  ${i+1}. ${m}`));
  
  await browser.close();
  return models;
}

test().catch(console.error);
