import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI JS CLICK ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);
  
  console.log('1. JS КЛИК НА div.current-model:');
  await page.evaluate(() => {
    const el = document.querySelector('div.current-model');
    if (el) {
      el.click();
      console.log('Clicked!');
    }
  });
  await page.waitForTimeout(3000);
  
  console.log('\n2. ПОИСК ОТКРЫТЫХ ЭЛЕМЕНТОВ:');
  const result = await page.evaluate(() => {
    const all = document.querySelectorAll('*');
    const visible = [];
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width > 50 && rect.height > 20) {
        const text = el.innerText?.trim();
        if (text && text.length > 2 && text.length < 100 && !text.includes('{') && !text.includes('[')) {
          const cls = el.className?.toString()?.substring(0, 50) || '';
          if (cls.includes('model') || cls.includes('option') || cls.includes('item') || cls.includes('popup') || cls.includes('dropdown')) {
            visible.push({ tag: el.tagName, cls, text: text.substring(0, 60) });
          }
        }
      }
    }
    return visible.slice(0, 20);
  });
  
  result.forEach((item, i) => console.log(`   ${i+1}. <${item.tag}> cls="${item.cls}" text="${item.text}"`));
  
  console.log('\n3. HTML СЕКЦИЯ С current-model:');
  const html = await page.evaluate(() => {
    const el = document.querySelector('div.current-model');
    return el ? el.outerHTML.substring(0, 2000) : 'not found';
  });
  console.log(html);
  
  await browser.close();
}

test().catch(console.error);
