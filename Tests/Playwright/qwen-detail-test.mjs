import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== QWEN DETAIL ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  console.log('1. ВСЕ КНОПКИ:');
  const buttons = await page.locator('button').all();
  for (let i = 0; i < Math.min(buttons.length, 20); i++) {
    const text = await buttons[i].textContent();
    const cls = await buttons[i].getAttribute('class');
    if (text?.trim()) {
      console.log(`   [${i}] "${text.trim().substring(0, 40)}" class="${cls?.substring(0, 50)}"`);
    }
  }
  
  console.log('\n2. ПОИСК "New Chat" / "Начать":');
  const texts = ['New Chat', 'Start', 'Begin', 'New', 'Создать', 'Начать', 'Chat'];
  for (const t of texts) {
    const count = await page.locator('*').filter({ hasText: new RegExp(t, 'i') }).count();
    if (count > 0) console.log(`   "${t}": ${count} элементов`);
  }
  
  console.log('\n3. ЭЛЕМЕНТЫ С "model":');
  const modelEls = await page.locator('[class*="model"], [class*="Model"]').all();
  for (let i = 0; i < Math.min(modelEls.length, 10); i++) {
    const cls = await modelEls[i].getAttribute('class');
    const text = await modelEls[i].textContent();
    console.log(`   [${i}] class="${cls?.substring(0, 60)}" text="${text?.trim().substring(0, 30)}"`);
  }
  
  await page.screenshot({ path: '/tmp/qwen-detail.png' });
  console.log('\n📸 /tmp/qwen-detail.png');
  
  await browser.close();
}

test().catch(console.error);
