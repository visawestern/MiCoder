import { chromium } from 'playwright';

const BASE_URL = 'https://kimi.moonshot.cn';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== ТЕСТ: Определение селекторов моделей Kimi ===\n');
  
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  
  console.log('1. Проверка селекторов НА ГЛАВНОЙ СТРАНИЦЕ:');
  const landingSelectors = [
    '[data-testid*="model"]',
    'button[aria-label*="odel"]',
    'div[class*="model-select"]',
    'button[class*="model"]',
  ];
  
  let foundOnLanding = false;
  for (const sel of landingSelectors) {
    const count = await page.locator(sel).count();
    console.log(`   ${sel}: ${count} элемент(ов)`);
    if (count > 0) {
      foundOnLanding = true;
      const text = await page.locator(sel).first().textContent();
      console.log(`     ✅ Текст: "${text?.substring(0, 60)}"`);
    }
  }
  
  if (!foundOnLanding) {
    console.log('   ❌ Селекторы НЕ найдены на главной — нужно начать чат');
    
    console.log('\n2. ПОИСК КНОПКИ "New Chat":');
    const newChatVariants = ['New Chat', '新对话', '开始聊天', 'New'];
    let clicked = false;
    for (const variant of newChatVariants) {
      const btn = page.locator('button, a, div').filter({ hasText: variant }).first();
      const visible = await btn.isVisible().catch(() => false);
      if (visible) {
        console.log(`   ✅ Найдена кнопка: "${variant}"`);
        await btn.click();
        clicked = true;
        await page.waitForTimeout(3000);
        break;
      }
    }
    if (!clicked) console.log('   ❌ Кнопка New Chat не найдена');
    
    console.log('\n3. ПОВТОРНАЯ ПРОВЕРКА СЕЛЕКТОРОВ (после New Chat):');
    for (const sel of landingSelectors) {
      const count = await page.locator(sel).count();
      console.log(`   ${sel}: ${count} элемент(ов)`);
      if (count > 0) {
        const text = await page.locator(sel).first().textContent();
        console.log(`     ✅ Текст: "${text?.substring(0, 60)}"`);
        
        // Кликаем чтобы открыть dropdown
        await page.locator(sel).first().click();
        await page.waitForTimeout(1000);
        
        console.log('\n4. СОДЕРЖИМОЕ DROPDOWN:');
        const options = await page.locator('[role="option"], [class*="option"], li').allTextContents();
        console.log(`   Найдено опций: ${options.length}`);
        options.slice(0, 10).forEach((opt, i) => console.log(`     ${i+1}. "${opt.trim().substring(0, 50)}"`));
      }
    }
  }
  
  await page.screenshot({ path: '/tmp/kimi-selectors.png', fullPage: false });
  console.log('\n📸 Скриншот: /tmp/kimi-selectors.png');
  
  await browser.close();
}

test().catch(console.error);
