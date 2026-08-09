import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== ДИАГНОСТИКА KIMI ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  
  console.log('1. ВСЕ КНОПКИ НА ГЛАВНОЙ:');
  const buttons = await page.locator('button').all();
  for (let i = 0; i < Math.min(buttons.length, 15); i++) {
    const text = await buttons[i].textContent();
    const cls = await buttons[i].getAttribute('class');
    console.log(`   [${i}] "${text?.trim().substring(0, 40)}" class="${cls?.substring(0, 50)}"`);
  }
  
  console.log('\n2. ВСЕ ЭЛЕМЕНТЫ С "model" В class ИЛИ attributes:');
  const modelElements = await page.locator('[class*="model"], [class*="Model"], [data-*="model"]').all();
  console.log(`   Найдено: ${modelElements.length}`);
  
  console.log('\n3. ПОПРОБУЕМ КЛИКНУТЬ "New Chat" (более точно):');
  const newChatBtn = page.locator('button').filter({ hasText: /New Chat|新对话/ }).first();
  const newChatCount = await newChatBtn.count();
  console.log(`   Кнопок "New Chat": ${newChatCount}`);
  
  if (newChatCount > 0) {
    await newChatBtn.click();
    await page.waitForTimeout(4000);
    
    console.log('\n4. ПОСЛЕ КЛИКА — ВСЕ КНОПКИ:');
    const buttonsAfter = await page.locator('button').all();
    for (let i = 0; i < Math.min(buttonsAfter.length, 20); i++) {
      const text = await buttonsAfter[i].textContent();
      const cls = await buttonsAfter[i].getAttribute('class');
      const ariaLabel = await buttonsAfter[i].getAttribute('aria-label');
      if (text?.trim() || ariaLabel) {
        console.log(`   [${i}] "${text?.trim().substring(0, 30)}" aria="${ariaLabel}" cls="${cls?.substring(0, 40)}"`);
      }
    }
    
    console.log('\n5. ПОСЛЕ КЛИКА — ПОИСК model-RELATED:');
    const allElements = await page.locator('*').all();
    let modelFound = 0;
    for (const el of allElements) {
      if (modelFound > 10) break;
      const cls = await el.getAttribute('class').catch(() => null);
      const aria = await el.getAttribute('aria-label').catch(() => null);
      const text = await el.textContent().catch(() => '');
      if (cls?.toLowerCase().includes('model') || aria?.toLowerCase().includes('model') || text?.toLowerCase().includes('kimi')) {
        modelFound++;
        console.log(`   model-related: cls="${cls?.substring(0, 50)}" aria="${aria}" text="${text?.substring(0, 30)}"`);
      }
    }
  }
  
  await page.screenshot({ path: '/tmp/kimi-after-click.png', fullPage: false });
  console.log('\n📸 Скриншот: /tmp/kimi-after-click.png');
  
  await browser.close();
}

test().catch(console.error);
