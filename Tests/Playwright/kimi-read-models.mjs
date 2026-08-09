import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI READ MODELS ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);
  
  console.log('1. КЛИК И ОЖИДАНИЕ DROPDOWN:');
  await page.locator('div.current-model').first().click();
  
  // Ждём появления model-item
  await page.waitForSelector('div.model-item', { timeout: 10000 });
  console.log('   ✅ dropdown открыт!');
  
  console.log('\n2. ЧИТАЕМ МОДЕЛИ:');
  const models = await page.evaluate(() => {
    const items = document.querySelectorAll('div.model-item');
    const result = [];
    for (const item of items) {
      const nameEl = item.querySelector('span.name');
      const descEl = item.querySelector('div.desc');
      if (nameEl) {
        result.push({
          name: nameEl.textContent.trim(),
          description: descEl?.textContent?.trim() || ''
        });
      }
    }
    return result;
  });
  
  console.log(`   Найдено моделей: ${models.length}`);
  models.forEach((m, i) => console.log(`   ${i+1}. ${m.name} — ${m.description}`));
  
  await browser.close();
  return models;
}

test().catch(console.error);
