import { chromium } from 'playwright';

async function test() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  console.log('=== KIMI PORTAL/TELEPORT ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);
  
  // Новый чат
  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);
  
  // Запоминаем HTML ДО клика
  const beforeHtml = await page.locator('body').innerHTML();
  
  // Клик
  await page.locator('div.current-model').first().click();
  await page.waitForTimeout(3000);
  
  // HTML ПОСЛЕ клика
  const afterHtml = await page.locator('body').innerHTML();
  
  // Находим новые элементы
  const beforeLen = beforeHtml.length;
  const afterLen = afterHtml.length;
  console.log(`HTML before: ${beforeLen} chars`);
  console.log(`HTML after: ${afterLen} chars`);
  console.log(`Difference: ${afterLen - beforeLen} chars`);
  
  // Ищем новые элементы внизу body
  console.log('\n1. ПОСЛЕДНИЕ 2000 СИМВОЛОВ HTML:');
  console.log(afterHtml.substring(afterHtml.length - 2000));
  
  await browser.close();
}

test().catch(console.error);
