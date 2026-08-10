import { chromium } from 'playwright';

async function researchQwenComplete() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('=== QWEN COMPLETE RESEARCH ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForTimeout(5000);

  const startBtn = page.locator('button').filter({ hasText: 'Начать' }).first();
  if (await startBtn.count() > 0) {
    await startBtn.click();
    await page.waitForTimeout(5000);
  }

  console.log('1. ALL INTERACTIVE ELEMENTS:');
  const allInteractive = await page.evaluate(() => {
    const result = [];
    const elements = document.querySelectorAll('button, [role="button"], [role="tab"], [role="radio"], [role="switch"], a, [class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [class*="tab"], [class*="radio"], [class*="mode"]');
    for (const el of elements) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 60) {
        const cls = el.className?.toString()?.substring(0, 60) || '';
        const tag = el.tagName;
        const role = el.getAttribute('role') || '';
        result.push({ tag, role, text: text.substring(0, 50), cls });
      }
    }
    const seen = new Set();
    return result.filter(item => {
      const key = item.text + item.cls;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  });
  allInteractive.forEach((item, i) => console.log(`   ${i+1}. [${item.tag}${item.role ? '/' + item.role : ''}] "${item.text}" cls="${item.cls}"`));

  console.log('\n2. SIDEBAR NAVIGATION:');
  const sidebar = await page.evaluate(() => {
    const result = [];
    const sidebar = document.querySelector('[class*="sidebar"], [class*="nav"], aside, nav');
    if (sidebar) {
      const items = sidebar.querySelectorAll('a, button, [role="button"], [class*="item"], [class*="nav"]');
      for (const el of items) {
        const rect = el.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) continue;
        const text = el.textContent?.trim();
        if (text && text.length > 1 && text.length < 40) result.push(text.substring(0, 40));
      }
    }
    return [...new Set(result)];
  });
  sidebar.forEach((item, i) => console.log(`   ${i+1}. ${item}`));

  console.log('\n3. FEATURE MODES (click model selector):');
  await page.locator('[class*="model-selector-text"]').first().click();
  await page.waitForTimeout(2500);
  
  const modes = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="mode"], [role="tab"], [role="button"], [class*="pill"], [class*="segment"]');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 1 && text.length < 40) {
        const cls = el.className?.toString()?.substring(0, 50) || '';
        result.push({ text: text.substring(0, 40), cls });
      }
    }
    return result;
  });
  modes.forEach(m => console.log(`   - "${m.text}" cls="${m.cls}"`));

  console.log('\n4. IMAGE GENERATION:');
  const imageFeatures = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('*');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const text = el.textContent?.trim();
      if (text && text.length < 40 && (text.includes('Image') || image.includes('изображ') || text.includes('图片')) && !text.includes('{')) {
        result.push(text.substring(0, 40));
      }
    }
    return [...new Set(result)];
  });
  imageFeatures.forEach(t => console.log(`   - ${t}`));

  await page.screenshot({ path: '/tmp/qwen-complete.png', fullPage: true });
  console.log('\n📸 /tmp/qwen-complete.png');

  await browser.close();
}

researchQwenComplete().catch(console.error);
