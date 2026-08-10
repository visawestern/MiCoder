import { chromium } from 'playwright';

async function testKimi() {
  console.log('\n=== KIMI E2E TEST ===\n');
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(8000);
  
  // Click new chat
  const newChat = page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first();
  if (await newChat.count() > 0) {
    await newChat.click();
    await page.waitForTimeout(5000);
  }
  
  // Find input
  const input = page.locator('textarea, div[contenteditable="true"]').first();
  const inputVisible = await input.isVisible().catch(() => false);
  console.log(`Input visible: ${inputVisible}`);
  
  if (inputVisible) {
    // Type message
    await input.fill('привет');
    await page.waitForTimeout(1000);
    
    // Find and click send button
    const sendBtn = page.locator('button').filter({ hasText: /send|отправить|↑/ }).or(page.locator('[aria-label*="end"], [aria-label*="send"]')).first();
    const sendVisible = await sendBtn.isVisible().catch(() => false);
    console.log(`Send button visible: ${sendVisible}`);
    
    if (sendVisible) {
      await sendBtn.click();
      console.log('Clicked send button');
      
      // Wait for response
      await page.waitForTimeout(10000);
      
      // Check for response
      const response = page.locator('[class*="message"], [class*="response"], [class*="markdown"]').last();
      const responseText = await response.textContent().catch(() => '');
      console.log(`Response: ${responseText?.substring(0, 200)}`);
    }
  }
  
  await page.screenshot({ path: '/tmp/kimi-e2e.png' });
  console.log('Screenshot: /tmp/kimi-e2e.png');
  
  await browser.close();
}

testKimi().catch(console.error);
