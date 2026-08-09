import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI OPEN DROPDOWN ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first().click();
  await page.waitForTimeout(5000);
  
  // Клик на модель
  await page.locator('div.current-model').first().click();
  await page.waitForTimeout(2000);
  
  console.log('1. ПОИСК ОТКРЫТОГО DROPDOWN:');
  const dropdownSelectors = [
    '[class*="model"][class*="list"]',
    '[class*="model"][class*="menu"]',
    '[class*="model"][class*="popup"]',
    '[class*="model"][class*="dropdown"]',
    '[class*="model"][class*="panel"]',
    '[class*="model"][class*="option"]',
    '[class*="model-picker"]',
    '[class*="model-selector"]',
    '[class*="dropdown"][class*="menu"]',
    '[class*="popup"][class*="content"]',
    '[class*="picker"][class*="panel"]',
    '[role="listbox"]',
    '[role="menu"]',
  ];
  
  for (const sel of dropdownSelectors) {
    const count = await page.locator(sel).count();
    if (count > 0) {
      const visible = await page.locator(sel).first().isVisible();
      console.log(`   ✅ ${sel}: ${count} elements, visible: ${visible}`);
      if (visible) {
        const text = await page.locator(sel).first().textContent();
        console.log(`      text: "${text?.substring(0, 150)}"`);
      }
    }
  }
  
  console.log('\n2. ПОИСК ПО ТЕКСТУ ОПЦИЙ:');
  const optionTexts = ['Быстрый чат', 'K3', 'K3 Swarm', 'Универсальная флагманская', 'Масштабный поиск'];
  for (const ot of optionTexts) {
    const count = await page.locator('*').filter({ hasText: ot }).count();
    if (count > 0) {
      console.log(`   ✅ "${ot}": ${count} elements`);
      const first = await page.locator('*').filter({ hasText: ot }).first();
      const cls = await first.getAttribute('class');
      const tag = await first.evaluate(e => e.tagName);
      console.log(`      <${tag}> class="${cls?.substring(0, 50)}"`);
    }
  }
  
  console.log('\n3. HTML С КЛАССОМ "active" ИЛИ "open":');
  const bodyHtml = await page.locator('body').innerHTML();
  const activeIdx = bodyHtml.indexOf('active');
  if (activeIdx > -1) {
    console.log(bodyHtml.substring(activeIdx - 100, activeIdx + 500));
  }
  
  await browser.close();
}

test().catch(console.error);
