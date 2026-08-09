import { chromium } from 'playwright';

async function testProvider(name, url, config) {
  console.log(`\n${'='.repeat(50)}`);
  console.log(`PROVIDER: ${name}`);
  console.log('='.repeat(50));
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(5000);
    
    console.log('\n1. ПОИСК КНОПКИ НОВОГО ЧАТА:');
    const newChatTexts = config.newChatTexts;
    let clicked = false;
    for (const text of newChatTexts) {
      const btn = page.locator('button, a, div').filter({ hasText: new RegExp(text, 'i') }).first();
      const count = await btn.count();
      if (count > 0) {
        console.log(`   ✅ Найдена: "${text}"`);
        await btn.click();
        clicked = true;
        await page.waitForTimeout(4000);
        break;
      }
    }
    if (!clicked) console.log('   ❌ Не найдена');
    
    console.log('\n2. ПОИСК КНОПКИ МОДЕЛИ:');
    const modelBtn = page.locator(config.modelButton).first();
    const modelBtnVisible = await modelBtn.isVisible().catch(() => false);
    console.log(`   ${config.modelButton}: ${modelBtnVisible ? '✅ видна' : '❌ не видна'}`);
    
    if (modelBtnVisible) {
      await modelBtn.click();
      await page.waitForTimeout(3000);
      
      console.log('\n3. МОДЕЛИ В DROPDOWN:');
      // Try multiple selectors for items
      const itemSelectors = config.itemSelectors;
      let models = [];
      
      for (const sel of itemSelectors) {
        const items = await page.locator(sel).all();
        if (items.length > 0) {
          console.log(`   ✅ Селектор "${sel}": ${items.length} элементов`);
          for (const item of items.slice(0, 10)) {
            const text = await item.textContent();
            if (text && text.trim().length > 0 && text.trim().length < 80) {
              models.push(text.trim());
            }
          }
          break;
        }
      }
      
      if (models.length > 0) {
        console.log(`   Найдено моделей: ${models.length}`);
        models.forEach((m, i) => console.log(`   ${i+1}. ${m.substring(0, 50)}`));
      } else {
        console.log('   ❌ Модели не найдены');
      }
      
      console.log('\n4. EFFORT/THINKING:');
      const effortBtn = page.locator(config.effortButton || '[class*="effort"], [class*="thinking"]').first();
      const effortVisible = await effortBtn.isVisible().catch(() => false);
      console.log(`   ${config.effortButton || '[class*="effort"]'}: ${effortVisible ? '✅ видна' : '❌ не видна'}`);
    }
    
    await page.screenshot({ path: `/tmp/${name}-screenshot.png` });
    console.log(`\n📸 Скриншот: /tmp/${name}-screenshot.png`);
    
  } catch (e) {
    console.log(`   ❌ Ошибка: ${e.message}`);
  }
  
  await browser.close();
}

// Test all providers
await testProvider('kimi', 'https://kimi.moonshot.cn', {
  newChatTexts: ['Новый чат', 'New Chat'],
  modelButton: 'div.current-model',
  itemSelectors: ['div.model-item span.name', 'div.model-item'],
  effortButton: 'div.effort-item'
});

await testProvider('qwen', 'https://chat.qwen.ai/', {
  newChatTexts: ['New Chat', '新对话', '开始新对话'],
  modelButton: '[class*="model"]',
  itemSelectors: ['[role="option"]', '[class*="option"]', 'div[class*="item"]', 'li'],
  effortButton: '[class*="effort"], [class*="thinking"]'
});

await testProvider('chatgpt', 'https://chatgpt.com/', {
  newChatTexts: ['New chat', 'New Chat'],
  modelButton: 'button[data-testid*="model"], button[class*="model"]',
  itemSelectors: ['[role="option"]', 'div[class*="option"]', 'li', 'div[class*="item"]'],
  effortButton: '[class*="effort"], [class*="thinking"]'
});

console.log('\n=== ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ===');
