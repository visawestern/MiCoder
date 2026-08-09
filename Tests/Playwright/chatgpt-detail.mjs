import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== CHATGPT DETAIL ===\n');
  await page.goto('https://chatgpt.com/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);
  
  console.log('1. КЛИК НА "ChatGPT" (кнопка модели):');
  const modelBtn = page.locator('button').filter({ hasText: 'ChatGPT' }).first();
  await modelBtn.click();
  await page.waitForTimeout(3000);
  
  console.log('\n2. HTML ПОСЛЕ КЛИКА (первые 3000):');
  const bodyHtml = await page.locator('body').innerHTML();
  // Ищем часть с моделями
  const menuIdx = bodyHtml.indexOf('menu');
  if (menuIdx > -1) {
    console.log(bodyHtml.substring(menuIdx, menuIdx + 2000));
  }
  
  await page.screenshot({ path: '/tmp/chatgpt-detail.png' });
  console.log('\n📸 /tmp/chatgpt-detail.png');
  
  await browser.close();
}

test().catch(console.error);
