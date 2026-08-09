import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== CHATGPT ===\n');
  await page.goto('https://chatgpt.com/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);
  
  console.log('1. КНОПКИ:');
  const buttons = await page.locator('button').all();
  for (let i = 0; i < Math.min(buttons.length, 15); i++) {
    const text = await buttons[i].textContent();
    const cls = await buttons[i].getAttribute('class');
    if (text?.trim()) console.log(`   [${i}] "${text.trim().substring(0, 30)}" cls="${cls?.substring(0, 40)}"`);
  }
  
  console.log('\n2. ПОИСК "New chat":');
  const newChat = page.locator('button, a').filter({ hasText: /New chat|New Chat/ }).first();
  const newChatCount = await newChat.count();
  console.log(`   Найдено: ${newChatCount}`);
  if (newChatCount > 0) {
    await newChat.click();
    await page.waitForTimeout(4000);
  }
  
  console.log('\n3. КНОПКА МОДЕЛИ:');
  const modelBtn = page.locator('button').filter({ hasText: /GPT|o1|o3|4o|model/i }).first();
  const modelBtnCount = await modelBtn.count();
  console.log(`   Найдено: ${modelBtnCount}`);
  if (modelBtnCount > 0) {
    const text = await modelBtn.textContent();
    console.log(`   Текст: "${text?.trim()}"`);
    await modelBtn.click();
    await page.waitForTimeout(3000);
    
    console.log('\n4. МОДЕЛИ В DROPDOWN:');
    const models = await page.evaluate(() => {
      const items = document.querySelectorAll('[role="option"], [class*="option"], li');
      return Array.from(items).slice(0, 10).map(el => el.textContent.trim()).filter(t => t.length > 0 && t.length < 50);
    });
    models.forEach((m, i) => console.log(`   ${i+1}. ${m}`));
  }
  
  await browser.close();
}

test().catch(console.error);
