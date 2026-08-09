import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI EXTRACT MODELS ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);
  
  // Клик на модель
  await page.locator('div.current-model').first().click();
  await page.waitForTimeout(3000);
  
  console.log('1. МОДЕЛИ В DROPDOWN:');
  const models = await page.evaluate(() => {
    const items = document.querySelectorAll('div.model-item');
    const result = [];
    for (const item of items) {
      const nameEl = item.querySelector('div.model-name span.name');
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
  models.forEach((m, i) => console.log(`   ${i+1}. ${m.name} — ${m.description.substring(0, 50)}`));
  
  console.log('\n2. СЕЛЕКТОРЫ ДЛЯ ПРИЛОЖЕНИЯ:');
  console.log('   Кнопка открытия: div.current-model');
  console.log('   Список моделей: div.model-item');
  console.log('   Название: div.model-name span.name');
  console.log('   Описание: div.desc');
  
  await browser.close();
  return models;
}

test().catch(console.error);
