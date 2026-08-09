import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI DROPDOWN STRUCTURE ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  const newChat = page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first();
  await newChat.click();
  await page.waitForTimeout(5000);
  
  // Клик на модель
  const modelBtn = page.locator('div.current-model').first();
  const modelVisible = await modelBtn.isVisible();
  console.log(`div.current-model visible: ${modelVisible}`);
  
  if (modelVisible) {
    await modelBtn.click();
    await page.waitForTimeout(2000);
    
    console.log('\n1. ПОИСК DROPDOWN:');
    const selectors = [
      '[class*="model-list"]',
      '[class*="model-select"]',
      '[class*="dropdown"]',
      '[class*="popup"]',
      '[class*="menu"]',
      '[role="listbox"]',
      '[role="option"]',
      '[class*="option"]',
    ];
    
    for (const sel of selectors) {
      const count = await page.locator(sel).count();
      if (count > 0) {
        const visible = await page.locator(sel).first().isVisible();
        if (visible) {
          console.log(`   ✅ ${sel}: ${count} элементов`);
          const text = await page.locator(sel).first().textContent();
          console.log(`      Текст: "${text?.substring(0, 80)}"`);
        }
      }
    }
    
    console.log('\n2. ПОИСК ТЕКСТА МОДЕЛЕЙ:');
    const modelTexts = ['Быстрый', 'K3', 'Swarm', 'Универсальная', 'флагманская'];
    for (const mt of modelTexts) {
      const count = await page.locator('*').filter({ hasText: mt }).count();
      if (count > 0) {
        console.log(`   ✅ "${mt}": ${count} элементов`);
        const texts = await page.locator('*').filter({ hasText: mt }).allTextContents();
        texts.slice(0, 3).forEach(t => console.log(`      - "${t?.trim().substring(0, 50)}"`));
      }
    }
  }
  
  await browser.close();
}

test().catch(console.error);
