import { chromium } from 'playwright';

async function researchKimiEffort() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('=== KIMI EFFORT/INTENSITY DEEP DIVE ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);

  // Enter chat
  await page.locator('button, a, div').filter({ hasText: /Новый чат/ }).first().click();
  await page.waitForTimeout(5000);

  // Click on effort/current-effort element
  console.log('1. CLICKING ON EFFORT ELEMENT (current-effort)');
  const effortEl = page.locator('[class*="current-effort"], [class*="effort"]').first();
  const effortCount = await effortEl.count();
  console.log(`   Found: ${effortCount}`);

  if (effortCount > 0) {
    const effortText = await effortEl.textContent();
    console.log(`   Text: "${effortText?.trim()}"`);

    await effortEl.click();
    await page.waitForTimeout(3000);

    console.log('\n2. OPTIONS AFTER CLICK:');
    const options = await page.evaluate(() => {
      const result = [];
      const all = document.querySelectorAll('[class*="effort"], [class*="option"], [class*="dropdown"], [class*="popup"], [role="option"], [role="listbox"]');
      for (const el of all) {
        const rect = el.getBoundingClientRect();
        const visible = rect.width > 0 && rect.height > 0;
        if (visible) {
          const text = el.textContent?.trim();
          if (text && text.length < 50) {
            result.push({ text, cls: el.className?.toString()?.substring(0, 50) });
          }
        }
      }
      return result;
    });
    options.forEach(o => console.log(`   - "${o.text}" cls="${o.cls}"`));

    // Look for intensity/deep thinking options
    console.log('\n3. LOOKING FOR INTENSITY/DEEP THINKING:');
    const intensityOptions = await page.evaluate(() => {
      const result = [];
      const all = document.querySelectorAll('*');
      for (const el of all) {
        const rect = el.getBoundingClientRect();
        const visible = rect.width > 0 && rect.height > 0;
        if (!visible) continue;
        const text = el.textContent?.trim();
        if (text && (text.includes('Интенсивность') || text.includes('Intensity') || text.includes('Глубок') || text.includes('Deep') || text.includes('思考') || text.includes('深度')) && text.length < 50) {
          result.push(text);
        }
      }
      return [...new Set(result)];
    });
    intensityOptions.forEach(t => console.log(`   - "${t}"`));
  }

  // Also look for any toggle/switch near the model selector
  console.log('\n4. ALL CLICKABLE ELEMENTS NEAR MODEL AREA:');
  const nearby = await page.evaluate(() => {
    const result = [];
    const modelBtn = document.querySelector('div.current-model');
    if (!modelBtn) return result;
    const parent = modelBtn.closest('div, section, header');
    if (!parent) return result;
    const clickables = parent.querySelectorAll('button, [role="button"], [class*="switch"], [class*="toggle"], [role="tab"], a');
    for (const el of clickables) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (visible) {
        result.push({ text: el.textContent?.trim().substring(0, 30), cls: el.className?.toString()?.substring(0, 40), tag: el.tagName });
      }
    }
    return result;
  });
  nearby.forEach(e => console.log(`   - "${e.text}" [${e.tag}] cls="${e.cls}"`));

  await page.screenshot({ path: '/tmp/kimi-effort.png' });
  console.log('\n📸 /tmp/kimi-effort.png');

  await browser.close();
}

async function researchQwenExpand() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('\n=== QWEN EXPAND MODELS DEEP DIVE ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);

  await page.locator('button').filter({ hasText: 'Начать' }).first().click();
  await page.waitForTimeout(5000);

  // Open model dropdown
  console.log('1. OPENING MODEL DROPDOWN');
  await page.locator('[class*="model-selector-text"]').first().click();
  await page.waitForTimeout(3000);

  // Get dropdown content and look for expand button
  console.log('\n2. DROPDOWN CONTENT:');
  const dropdownContent = await page.evaluate(() => {
    const dropdowns = document.querySelectorAll('[class*="dropdown"], [class*="popup"], [class*="menu"], [class*="picker"], [class*="select"], [role="listbox"]');
    const result = [];
    for (const dd of dropdowns) {
      const rect = dd.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (visible) {
        const html = dd.innerHTML.substring(0, 2000);
        const text = dd.textContent?.trim().substring(0, 500);
        result.push({ text, html });
      }
    }
    return result;
  });
  dropdownContent.forEach((dd, i) => {
    console.log(`   Dropdown ${i+1}: "${dd.text?.substring(0, 200)}"`);
  });

  // Look for expand button specifically
  console.log('\n3. EXPAND BUTTON (comprehensive search):');
  const expandKeywords = ['expand', 'more', 'show', 'ещё', '更多', '展开', 'See all', 'View all', 'Show all'];
  for (const kw of expandKeywords) {
    const els = await page.locator('*').filter({ hasText: new RegExp(kw, 'i') }).all();
    for (const el of els) {
      const rect = await el.boundingBox();
      if (rect && rect.width > 0) {
        const text = await el.textContent();
        console.log(`   Found "${kw}": "${text?.trim().substring(0, 40)}"`);
      }
    }
  }

  // Scroll inside dropdown if it exists
  console.log('\n4. SCROLLING INSIDE DROPDOWN:');
  const scrollResult = await page.evaluate(async () => {
    const dropdowns = document.querySelectorAll('[class*="dropdown"], [class*="popup"], [class*="menu"], [role="listbox"]');
    for (const dd of dropdowns) {
      const rect = dd.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        // Try to scroll
        const scrollHeight = dd.scrollHeight;
        const clientHeight = dd.clientHeight;
        if (scrollHeight > clientHeight) {
          dd.scrollTop = scrollHeight;
          await new Promise(r => setTimeout(r, 1000));
          // Check for new items after scroll
          const items = dd.querySelectorAll('[class*="model-item"], [class*="item"]');
          return { scrolled: true, items: items.length };
        }
      }
    }
    return { scrolled: false, items: 0 };
  });
  console.log(`   Scroll result:`, scrollResult);

  await page.screenshot({ path: '/tmp/qwen-expand.png' });
  console.log('\n📸 /tmp/qwen-expand.png');

  await browser.close();
}

await researchKimiEffort();
await researchQwenExpand();
