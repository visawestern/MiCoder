import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI FULL TEXT ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first().click();
  await page.waitForTimeout(5000);
  
  // Клик на стрелку
  await page.locator('div.current-model svg.arrow').first().click();
  await page.waitForTimeout(3000);
  
  console.log('1. ВЕСЬ ТЕКСТ СТРАНИЦЫ:');
  const bodyText = await page.locator('body').textContent();
  // Ищем часть с моделями
  const lines = bodyText.split('\n').filter(l => l.trim().length > 0 && l.trim().length < 100);
  for (const line of lines.slice(0, 50)) {
    if (line.includes('ыстрый') || line.includes('K3') || line.includes('модел') || line.includes('модель') || line.includes('chat') || line.includes('Chat')) {
      console.log(`   >> ${line.trim()}`);
    }
  }
  
  console.log('\n2. ПОИСК ПО КЛАССУ "model-name" ИЛИ "option":');
  const modelNames = await page.locator('[class*="model-name"], [class*="option"], [class*="item"]').allTextContents();
  console.log(`   Найдено: ${modelNames.length}`);
  modelNames.slice(0, 20).forEach((t, i) => console.log(`   ${i+1}. "${t?.trim()}"`));
  
  await browser.close();
}

test().catch(console.error);
