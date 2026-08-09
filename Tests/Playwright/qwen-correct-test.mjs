import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== QWEN CORRECT ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Клик "Начать"
  await page.locator('button').filter({ hasText: 'Начать' }).first().click();
  await page.waitForTimeout(4000);
  
  console.log('1. КЛИК НА ТЕКСТ МОДЕЛИ:');
  const modelEl = page.locator('[class*="model-selector-text"]').first();
  const modelText = await modelEl.textContent();
  console.log(`   Текущая модель: "${modelText}"`);
  await modelEl.click();
  await page.waitForTimeout(3000);
  
  console.log('\n2. DROPDOWN CONTENT:');
  // Ищем все видимые элементы с текстом
  const allDivs = await page.locator('div').all();
  const visibleTexts = [];
  for (const div of allDivs) {
    const visible = await div.isVisible();
    if (visible) {
      const text = await div.textContent();
      const cls = await div.getAttribute('class');
      if (text && text.trim().length > 2 && text.trim().length < 80 && cls?.includes('model')) {
        visibleTexts.push({ text: text.trim().substring(0, 50), cls: cls.substring(0, 50) });
      }
    }
  }
  visibleTexts.slice(0, 15).forEach((item, i) => console.log(`   ${i+1}. "${item.text}" cls="${item.cls}"`));
  
  await page.screenshot({ path: '/tmp/qwen-correct.png' });
  console.log('\n📸 /tmp/qwen-correct.png');
  
  await browser.close();
}

test().catch(console.error);
