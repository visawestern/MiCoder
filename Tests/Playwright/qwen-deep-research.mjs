import { chromium } from 'playwright';

async function researchQwen() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('=== QWEN DEEP RESEARCH ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);

  // Enter chat
  console.log('1. ENTERING CHAT');
  const startBtn = page.locator('button').filter({ hasText: 'Начать' }).first();
  if (await startBtn.count() > 0) {
    await startBtn.click();
    await page.waitForTimeout(5000);
    console.log('   Clicked "Начать"');
  }

  // DOCUMENT: Model selector and initial models
  console.log('\n2. MODELS (initial)');
  await page.locator('[class*="model-selector-text"]').first().click();
  await page.waitForTimeout(3000);

  let models = await page.evaluate(() => {
    const items = document.querySelectorAll('[class*="model-item-name"]');
    return Array.from(items).map(el => ({
      name: el.textContent?.trim(),
      desc: el.closest('[class*="model-item"]')?.querySelector('[class*="desc"]')?.textContent?.trim()
    }));
  });
  console.log(`   Found ${models.length} models:`);
  models.forEach((m, i) => console.log(`   ${i+1}. ${m.name} — ${m.desc?.substring(0, 50)}`));

  // DOCUMENT: Expand more models
  console.log('\n3. EXPAND MORE MODELS');
  const expandTexts = ['Expand more', 'Show more', '更多', 'Показать ещё', '展开更多', '更多模型', 'ещё'];
  for (const text of expandTexts) {
    const btn = page.locator('*').filter({ hasText: new RegExp(text, 'i') }).first();
    const count = await btn.count();
    if (count > 0) {
      const rect = await btn.boundingBox();
      if (rect && rect.width > 0) {
        console.log(`   Found: "${text}" — clicking...`);
        await btn.click();
        await page.waitForTimeout(3000);
        models = await page.evaluate(() => {
          const items = document.querySelectorAll('[class*="model-item-name"]');
          return Array.from(items).map(el => ({
            name: el.textContent?.trim(),
            desc: el.closest('[class*="model-item"]')?.querySelector('[class*="desc"]')?.textContent?.trim()
          }));
        });
        console.log(`   After expand: ${models.length} models`);
        models.forEach((m, i) => console.log(`   ${i+1}. ${m.name} — ${m.desc?.substring(0, 50)}`));
        break;
      }
    }
  }

  // DOCUMENT: Mode switches (auto/think/fast)
  console.log('\n4. MODE SWITCHES');
  // Close model dropdown first
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  const switches = await page.evaluate(() => {
    const result = [];
    const elements = document.querySelectorAll('[class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [class*="mode"], [class*="tab"], [role="tab"], [role="radio"], [role="button"]');
    for (const el of elements) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      const text = el.textContent?.trim();
      if (text && text.length < 30 && visible) {
        const cls = el.className?.toString()?.substring(0, 50) || '';
        result.push({ text, cls, tag: el.tagName });
      }
    }
    return result;
  });
  console.log(`   Found ${switches.length} switch elements:`);
  switches.slice(0, 20).forEach(s => console.log(`   - "${s.text}" [${s.tag}] cls="${s.cls}"`));

  // DOCUMENT: Special modes (image, deep thinking)
  console.log('\n5. SPECIAL MODES');
  const specialModes = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('*');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (!visible) continue;
      const text = el.textContent?.trim();
      const cls = el.className?.toString() || '';
      if (text && text.length < 40 && (text.includes('Image') || text.includes('Think') || text.includes('Deep') || text.includes('图片') || text.includes('深度') || text.includes('思考')) && !text.includes('{')) {
        result.push({ text: text.substring(0, 40), cls: cls.substring(0, 40) });
      }
    }
    return result;
  });
  console.log(`   Found ${specialModes.length} special mode elements:`);
  specialModes.slice(0, 15).forEach(m => console.log(`   - "${m.text}" cls="${m.cls}"`));

  // DOCUMENT: Effort/thinking levels
  console.log('\n6. EFFORT LEVELS');
  const effortLevels = await page.evaluate(() => {
    const result = [];
    const efforts = document.querySelectorAll('[class*="effort"], [class*="thinking"], [class*="depth"], [class*="intensity"]');
    for (const el of efforts) {
      const rect = el.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        result.push({ text: el.textContent?.trim(), cls: el.className?.toString()?.substring(0, 50) });
      }
    }
    return result;
  });
  console.log(`   Found ${effortLevels.length} effort elements:`);
  effortLevels.forEach(e => console.log(`   - "${e.text}" cls="${e.cls}"`));

  // DOCUMENT: Per-model modes
  console.log('\n7. PER-MODEL MODES');
  await page.locator('[class*="model-selector-text"]').first().click();
  await page.waitForTimeout(2000);
  const modelItems = await page.locator('[class*="model-item"]').all();
  const modelModes = {};
  for (let i = 0; i < modelItems.length; i++) {
    await modelItems[i].click();
    await page.waitForTimeout(2000);
    const modelName = await modelItems[i].querySelector('[class*="model-item-name"]')?.textContent?.trim();

    const available = await page.evaluate(() => {
      const els = document.querySelectorAll('[class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [role="tab"], [role="radio"]');
      return Array.from(els).filter(el => {
        const rect = el.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
      }).map(el => el.textContent?.trim()).filter(t => t && t.length < 20);
    });

    modelModes[modelName || `model${i}`] = available;
    console.log(`   "${modelName}":`, available);
  }

  await page.screenshot({ path: '/tmp/qwen-deep.png', fullPage: false });
  console.log('\n📸 Screenshot: /tmp/qwen-deep.png');

  await browser.close();
  return { models, switches, specialModes, effortLevels, modelModes };
}

researchQwen().catch(console.error);
