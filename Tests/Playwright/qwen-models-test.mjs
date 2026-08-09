import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== QWEN MODELS ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Клик "Начать"
  const startBtn = page.locator('button').filter({ hasText: 'Начать' }).first();
  await startBtn.click();
  await page.waitForTimeout(4000);
  
  console.log('1. КЛИК НА СЕЛЕКТОР МОДЕЛИ:');
  const modelSelector = page.locator('[class*="model-selector"]').first();
  await modelSelector.click();
  await page.waitForTimeout(3000);
  
  console.log('\n2. МОДЕЛИ В DROPDOWN:');
  const items = await page.locator('[class*="model-item"], [class*="option"], li, div[class*="item"]').all();
  const models = [];
  for (const item of items.slice(0, 20)) {
    const text = await item.textContent();
    if (text && text.trim().length > 0 && text.trim().length < 100) {
      const cls = await item.getAttribute('class');
      console.log(`   - "${text.trim().substring(0, 50)}" cls="${cls?.substring(0, 40)}"`);
      models.push(text.trim());
    }
  }
  
  console.log(`\n   ИТОГО: ${models.length} моделей`);
  
  await page.screenshot({ path: '/tmp/qwen-models.png' });
  console.log('\n📸 /tmp/qwen-models.png');
  
  await browser.close();
}

test().catch(console.error);
