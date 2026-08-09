import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== CHATGPT FINAL ===\n');
  await page.goto('https://chatgpt.com/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(4000);
  
  // Закрываем cookie popup
  console.log('1. ЗАКРЫВАЕМ POPUPS:');
  const rejectBtn = page.locator('button').filter({ hasText: /Отклонить|Reject|Decline|Отказаться/i }).first();
  if (await rejectBtn.count() > 0) {
    await rejectBtn.click();
    console.log('   ✅ Cookie popup закрыт');
    await page.waitForTimeout(1000);
  }
  
  const closePromo = page.locator('button[aria-label*="Close"], button').filter({ hasText: /Закрыть|Close|×/ }).first();
  if (await closePromo.count() > 0) {
    await closePromo.click();
    console.log('   ✅ Promo popup закрыт');
    await page.waitForTimeout(1000);
  }
  
  console.log('\n2. КЛИК НА model-switcher-dropdown-button:');
  const modelBtn = page.locator('button[data-testid="model-switcher-dropdown-button"]').first();
  const modelBtnVisible = await modelBtn.isVisible();
  console.log(`   Кнопка видна: ${modelBtnVisible}`);
  
  if (modelBtnVisible) {
    const textBefore = await modelBtn.textContent();
    console.log(`   Текст до клика: "${textBefore?.trim()}"`);
    
    await modelBtn.click();
    await page.waitForTimeout(3000);
    
    console.log('\n3. ПОИСК МОДЕЛЕЙ:');
    // Ищем всё с "GPT" или "o1"
    const allElements = await page.locator('*').all();
    const modelCandidates = [];
    for (const el of allElements) {
      const visible = await el.isVisible().catch(() => false);
      if (!visible) continue;
      const text = await el.textContent().catch(() => '');
      if (text && (text.includes('GPT') || text.includes('o1') || text.includes('o3')) && text.trim().length < 100) {
        const cls = await el.getAttribute('class').catch(() => '');
        const tag = await el.evaluate(e => e.tagName).catch(() => '?');
        modelCandidates.push({ text: text.trim().substring(0, 50), cls: cls?.substring(0, 40), tag });
      }
    }
    
    modelCandidates.slice(0, 15).forEach((m, i) => console.log(`   ${i+1}. <${m.tag}> "${m.text}" cls="${m.cls}"`));
  }
  
  await browser.close();
}

test().catch(console.error);
