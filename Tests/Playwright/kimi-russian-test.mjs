import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI НА РУССКОМ ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  
  console.log('1. ПОИСК КНОПКИ НОВОГО ЧАТА:');
  const chatButtonVariants = [
    'Новый чат', 'Начать чат', 'Новый', 'Создать', 'Начать',
    'New Chat', 'Start Chat', 'Create'
  ];
  
  for (const variant of chatButtonVariants) {
    const btn = page.locator('button, a, div').filter({ hasText: variant }).first();
    const count = await btn.count();
    if (count > 0) {
      console.log(`   ✅ Найдена: "${variant}"`);
      await btn.click();
      await page.waitForTimeout(4000);
      break;
    }
  }
  
  console.log('\n2. ПОСЛЕ КЛИКА — ПОИСК СЕЛЕКТОРА МОДЕЛИ:');
  const modelSelectors = [
    '[data-testid*="model"]',
    'button[aria-label*="модель" i]',
    'button[aria-label*="model" i]',
    'div[class*="model"]',
    'div[class*="Model"]',
    'button[class*="model"]',
    'button[class*="Model"]',
    '[class*="select"]',
    '[class*="Select"]',
    '[role="combobox"]',
    '[role="listbox"]',
  ];
  
  for (const sel of modelSelectors) {
    const count = await page.locator(sel).count();
    if (count > 0) {
      console.log(`   ✅ ${sel}: ${count} элемент(ов)`);
      const text = await page.locator(sel).first().textContent();
      console.log(`      Текст: "${text?.substring(0, 60)}"`);
      
      // Кликнуть и посмотреть dropdown
      await page.locator(sel).first().click();
      await page.waitForTimeout(1500);
      
      console.log('\n3. СОДЕРЖИМОЕ DROPDOWN:');
      const options = await page.locator('[role="option"], [class*="option"], li, div[class*="item"]').allTextContents();
      const filtered = options.filter(t => t.trim().length > 0 && t.trim().length < 100).slice(0, 15);
      console.log(`   Опций: ${filtered.length}`);
      filtered.forEach((opt, i) => console.log(`     ${i+1}. "${opt.trim()}"`));
      
      break;
    }
  }
  
  await page.screenshot({ path: '/tmp/kimi-russian.png', fullPage: false });
  console.log('\n📸 Скриншот: /tmp/kimi-russian.png');
  
  await browser.close();
}

test().catch(console.error);
