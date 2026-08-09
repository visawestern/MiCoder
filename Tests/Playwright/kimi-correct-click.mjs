import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI CORRECT CLICK ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);
  
  console.log('1. КЛИК НА div.current-model (не стрелку!):');
  const modelBtn = page.locator('div.current-model').first();
  await modelBtn.click();
  await page.waitForTimeout(4000); // Ждём анимацию
  
  console.log('2. ПОИСК DROPDOWN:');
  const dropdown = page.locator('[class*="model"][class*="list"], [class*="dropdown"], [class*="popup"], [class*="picker"]').first();
  const dropdownVisible = await dropdown.isVisible().catch(() => false);
  console.log(`   dropdown visible: ${dropdownVisible}`);
  
  console.log('\n3. ПОИСК ОПЦИЙ ПО ТЕКСТУ:');
  const optionTexts = ['Быстрый', 'K3', 'Swarm'];
  for (const ot of optionTexts) {
    const elements = await page.locator('*').filter({ hasText: ot }).all();
    for (const el of elements.slice(0, 3)) {
      const visible = await el.isVisible();
      if (visible) {
        const text = await el.textContent();
        const cls = await el.getAttribute('class');
        console.log(`   ✅ "${ot}": text="${text?.trim().substring(0, 40)}" cls="${cls?.substring(0, 40)}"`);
      }
    }
  }
  
  await page.screenshot({ path: '/tmp/kimi-correct-click.png' });
  console.log('\n📸 Скриншот: /tmp/kimi-correct-click.png');
  
  await browser.close();
}

test().catch(console.error);
