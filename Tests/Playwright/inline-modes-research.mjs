import { chromium } from 'playwright';

async function researchKimiInlineModes() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('=== KIMI INLINE MODE SWITCHES ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(7000);

  // Enter chat
  const newChat = page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first();
  await newChat.waitFor({ timeout: 10000 }).catch(() => {});
  if (await newChat.count() > 0) {
    await newChat.click();
    await page.waitForTimeout(5000);
  }

  console.log('1. ELEMENTS BELOW CHAT INPUT:');
  const inputArea = await page.evaluate(() => {
    const textarea = document.querySelector('textarea, div[contenteditable="true"], [class*="input"]');
    if (!textarea) return null;
    let parent = textarea.parentElement;
    let container = null;
    while (parent) {
      if (parent.querySelector('[class*="switch"], [class*="toggle"], [role="tab"], [role="radio"], button')) {
        container = parent;
        break;
      }
      parent = parent.parentElement;
    }
    return container ? container.innerHTML.substring(0, 3000) : null;
  });
  if (inputArea) console.log(inputArea);

  console.log('\n2. INLINE SWITCHES/TOGGLES:');
  const inlineSwitches = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="switch"], [class*="toggle"], [role="tab"], [role="radio"], [class*="pill"], [class*="segment"], [class*="mode"], [class*="footer"], [class*="action"]');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 50) {
        const cls = el.className?.toString()?.substring(0, 60) || '';
        result.push({ text: text.substring(0, 40), cls, tag: el.tagName, y: rect.y });
      }
    }
    return result.sort((a, b) => a.y - b.y);
  });
  inlineSwitches.slice(0, 20).forEach(s => console.log(`   "${s.text}" [${s.tag}] cls="${s.cls}" y=${s.y}`));

  console.log('\n3. BOTTOM TOOLBAR / FOOTER:');
  const toolbar = await page.evaluate(() => {
    const result = [];
    const elements = document.querySelectorAll('[class*="footer"], [class*="toolbar"], [class*="action"], [class*="bottom"]');
    for (const el of elements) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      if (rect.y < window.innerHeight * 0.5) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 100) {
        const cls = el.className?.toString()?.substring(0, 60) || '';
        result.push({ text: text.substring(0, 60), cls, y: rect.y });
      }
    }
    return result;
  });
  toolbar.forEach(t => console.log(`   "${t.text}" cls="${t.cls}" y=${t.y}`));

  await page.screenshot({ path: '/tmp/kimi-inline.png', fullPage: true });
  console.log('\n📸 /tmp/kimi-inline.png');

  await browser.close();
}

async function researchQwenInlineModes() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('\n=== QWEN INLINE MODE SWITCHES ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(7000);

  const startBtn = page.locator('button').filter({ hasText: 'Начать' }).first();
  await startBtn.waitFor({ timeout: 10000 }).catch(() => {});
  if (await startBtn.count() > 0) {
    await startBtn.click();
    await page.waitForTimeout(5000);
  }

  console.log('1. ELEMENTS BELOW CHAT INPUT:');
  const inputArea = await page.evaluate(() => {
    const textarea = document.querySelector('textarea, div[contenteditable="true"], [class*="input"]');
    if (!textarea) return null;
    let parent = textarea.parentElement;
    let container = null;
    while (parent) {
      if (parent.querySelector('[class*="switch"], [class*="toggle"], [role="tab"], [role="radio"], button')) {
        container = parent;
        break;
      }
      parent = parent.parentElement;
    }
    return container ? container.innerHTML.substring(0, 3000) : null;
  });
  if (inputArea) console.log(inputArea);

  console.log('\n2. INLINE SWITCHES/TOGGLES:');
  const inlineSwitches = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="switch"], [class*="toggle"], [role="tab"], [role="radio"], [class*="pill"], [class*="segment"], [class*="mode"], [class*="footer"], [class*="action"]');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 50) {
        const cls = el.className?.toString()?.substring(0, 60) || '';
        result.push({ text: text.substring(0, 40), cls, tag: el.tagName, y: rect.y });
      }
    }
    return result.sort((a, b) => a.y - b.y);
  });
  inlineSwitches.slice(0, 25).forEach(s => console.log(`   "${s.text}" [${s.tag}] cls="${s.cls}" y=${s.y}`));

  await page.screenshot({ path: '/tmp/qwen-inline.png', fullPage: true });
  console.log('\n📸 /tmp/qwen-inline.png');

  await browser.close();
}

await researchKimiInlineModes();
await researchQwenInlineModes();
