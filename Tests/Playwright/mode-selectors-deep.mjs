import { chromium } from 'playwright';

async function researchKimiModes() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('=== KIMI MODE OPTIONS ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(8000);

  const newChat = page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first();
  await newChat.waitFor({ timeout: 15000 }).catch(() => console.log('   New chat button not found, trying without click'));
  if (await newChat.count() > 0) {
    await newChat.click();
    await page.waitForTimeout(5000);
  }

  console.log('1. CLICKING current-model:');
  await page.locator('div.current-model').first().click();
  await page.waitForTimeout(3000);

  const modelOptions = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="model-item"], [role="option"], [class*="option"]');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 60) {
        result.push({ text: text.substring(0, 50), cls: el.className?.toString()?.substring(0, 50) });
      }
    }
    return result;
  });
  modelOptions.forEach(o => console.log(`   - "${o.text}" cls="${o.cls}"`));

  console.log('\n2. CLICKING effort selector:');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);
  await page.locator('[class*="effort"]').first().click();
  await page.waitForTimeout(3000);

  const effortOptions = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="effort"], [role="option"], [class*="option"]');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 60) {
        result.push({ text: text.substring(0, 50), cls: el.className?.toString()?.substring(0, 50) });
      }
    }
    return result;
  });
  effortOptions.forEach(o => console.log(`   - "${o.text}" cls="${o.cls}"`));

  await browser.close();
}

async function researchQwenModes() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('\n=== QWEN MODE OPTIONS ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(8000);

  const startBtn = page.locator('button').filter({ hasText: 'Начать|Get Started|Start/' }).first();
  await startBtn.waitFor({ timeout: 15000 }).catch(() => console.log('   Start button not found'));
  if (await startBtn.count() > 0) {
    await startBtn.click();
    await page.waitForTimeout(5000);
  }

  console.log('1. CLICKING mode-select:');
  await page.locator('[class*="mode-select"]').first().click();
  await page.waitForTimeout(3000);

  const modeOptions = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="mode-option"], [role="option"], [class*="option"], [class*="dropdown"] li, [class*="menu"] li');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 60) {
        result.push({ text: text.substring(0, 50), cls: el.className?.toString()?.substring(0, 50) });
      }
    }
    return result;
  });
  modeOptions.forEach(o => console.log(`   - "${o.text}" cls="${o.cls}"`));

  console.log('\n2. CLICKING thinking-selector:');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);
  await page.locator('[class*="qwen-select-thinking"]').first().click();
  await page.waitForTimeout(3000);

  const thinkingOptions = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="thinking"], [role="option"], [class*="option"], [class*="select"] [class*="item"]');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 60) {
        result.push({ text: text.substring(0, 50), cls: el.className?.toString()?.substring(0, 50) });
      }
    }
    return result;
  });
  thinkingOptions.forEach(o => console.log(`   - "${o.text}" cls="${o.cls}"`));

  console.log('\n3. CLICKING model selector:');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);
  await page.locator('[class*="model-selector-text"]').first().click();
  await page.waitForTimeout(3000);

  const modelOptions = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="model-item"], [role="option"]');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 80) {
        result.push({ text: text.substring(0, 70), cls: el.className?.toString()?.substring(0, 50) });
      }
    }
    return result;
  });
  modelOptions.forEach(o => console.log(`   - "${o.text}" cls="${o.cls}"`));

  await browser.close();
}

await researchKimiModes();
await researchQwenModes();
