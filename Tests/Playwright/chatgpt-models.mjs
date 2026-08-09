import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== CHATGPT MODELS ===\n');
  await page.goto('https://chatgpt.com/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);
  
  console.log('1. ПОИСК СЕЛЕКТОРА МОДЕЛИ:');
  const selectors = [
    'button[data-testid="model-selector"]',
    'button[data-testid*="model"]',
    '[class*="model-selector"]',
    '[class*="model-picker"]',
    '[class*="modelButton"]',
    'button:has-text("GPT-4o")',
    'button:has-text("o1")',
    'button:has-text("o3")',
  ];
  
  for (const sel of selectors) {
    const count = await page.locator(sel).count();
    if (count > 0) {
      const text = await page.locator(sel).first().textContent();
      console.log(`   ✅ ${sel}: "${text?.trim().substring(0, 30)}"`);
    }
  }
  
  console.log('\n2. КЛИК НА КНОПКУ С ТЕКСТОМ "ChatGPT" ИЛИ "GPT":');
  const modelButton = page.locator('button').filter({ hasText: /ChatGPT|GPT|o1|o3|4o/ }).first();
  const modelBtnCount = await modelButton.count();
  if (modelBtnCount > 0) {
    const text = await modelButton.textContent();
    console.log(`   Найдена: "${text?.trim()}"`);
    
    // Получаем класс
    const cls = await modelButton.getAttribute('class');
    console.log(`   class: "${cls?.substring(0, 60)}"`);
    
    await modelButton.click();
    await page.waitForTimeout(3000);
    
    console.log('\n3. ПОСЛЕ КЛИКА — ИЩЕМ ОПЦИИ:');
    const options = await page.evaluate(() => {
      const items = document.querySelectorAll('[role="option"], [role="menuitem"], [class*="option"], [class*="model-item"]');
      return Array.from(items).slice(0, 15).map(el => ({
        text: el.textContent.trim().substring(0, 50),
        cls: el.className?.toString()?.substring(0, 40) || '',
        tag: el.tagName
      }));
    });
    
    options.forEach((opt, i) => console.log(`   ${i+1}. <${opt.tag}> "${opt.text}" cls="${opt.cls}"`));
  }
  
  await browser.close();
}

test().catch(console.error);
