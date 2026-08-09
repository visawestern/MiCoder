import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== ФИНАЛЬНЫЙ ТЕСТ KIMI ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  
  // Клик "Новый чат"
  const newChat = page.locator('button, a, div').filter({ hasText: 'Новый чат' }).first();
  await newChat.click();
  await page.waitForTimeout(4000);
  
  console.log('1. ТОЧНЫЙ СЕЛЕКТОР КНОПКИ МОДЕЛИ:');
  const modelBtn = page.locator('div[class*="model"]').first();
  const modelBtnClass = await modelBtn.getAttribute('class');
  console.log(`   class: "${modelBtnClass}"`);
  const modelBtnText = await modelBtn.textContent();
  console.log(`   text: "${modelBtnText}"`);
  
  // Клик чтобы открыть dropdown
  await modelBtn.click();
  await page.waitForTimeout(1500);
  
  console.log('\n2. МОДЕЛИ В DROPDOWN:');
  // Ищем конкретные опции
  const options = await page.locator('[class*="option"], [role="option"]').all();
  const models = [];
  for (const opt of options) {
    const text = await opt.textContent();
    const cls = await opt.getAttribute('class');
    if (text && text.trim().length > 0 && text.trim().length < 100) {
      console.log(`   - "${text.trim()}" (cls: ${cls?.substring(0, 40)})`);
      models.push(text.trim());
    }
  }
  
  console.log('\n3. СТРУКТУРА DROPDOWN:');
  const dropdownHtml = await page.locator('[class*="dropdown"], [class*="menu"], [class*="picker"]').first().innerHTML().catch(() => 'not found');
  console.log(`   HTML (first 500): ${dropdownHtml?.substring(0, 500)}`);
  
  console.log(`\n✅ ИТОГО МОДЕЛЕЙ: ${models.length}`);
  models.forEach((m, i) => console.log(`   ${i+1}. ${m}`));
  
  await browser.close();
  return models;
}

test().catch(console.error);
