import { chromium } from 'playwright';

async function researchKimi() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('=== KIMI DEEP RESEARCH ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);

  // Enter chat
  console.log('1. ENTERING CHAT');
  const newChatBtn = page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first();
  if (await newChatBtn.count() > 0) {
    await newChatBtn.click();
    await page.waitForTimeout(5000);
    console.log('   Clicked "Новый чат"');
  }

  // DOCUMENT: All models
  console.log('\n2. MODELS (clicking div.current-model)');
  await page.locator('div.current-model').first().click();
  await page.waitForTimeout(3000);

  let models = await page.evaluate(() => {
    const items = document.querySelectorAll('div.model-item');
    return Array.from(items).map(el => ({
      name: el.querySelector('span.name')?.textContent?.trim(),
      description: el.querySelector('div.desc')?.textContent?.trim(),
    }));
  });
  console.log(`   Found ${models.length} models (initial):`);
  models.forEach((m, i) => console.log(`   ${i+1}. ${m.name} — ${m.description?.substring(0, 50)}`));

  // DOCUMENT: Expand more models
  console.log('\n3. LOOKING FOR "Expand more models"');
  const expandTexts = ['Expand more', 'Show more', '更多', 'Показать ещё', '展开更多', 'ещё', '更多模型'];
  for (const text of expandTexts) {
    const btn = page.locator('*').filter({ hasText: new RegExp(text, 'i') }).first();
    const count = await btn.count();
    if (count > 0) {
      const visible = await btn.isVisible();
      if (visible) {
        console.log(`   Found: "${text}" - clicking...`);
        await btn.click();
        await page.waitForTimeout(2000);
        models = await page.evaluate(() => {
          const items = document.querySelectorAll('div.model-item');
          return Array.from(items).map(el => ({
            name: el.querySelector('span.name')?.textContent?.trim(),
            description: el.querySelector('div.desc')?.textContent?.trim(),
          }));
        });
        console.log(`   After expand: ${models.length} models`);
        models.forEach((m, i) => console.log(`   ${i+1}. ${m.name} — ${m.description?.substring(0, 50)}`));
        break;
      }
    }
  }

  // DOCUMENT: Mode switches (auto/think/fast)
  console.log('\n4. MODE SWITCHES (auto/think/fast)');
  await page.locator('div.current-model').first().click();
  await page.waitForTimeout(2000);

  const switches = await page.evaluate(() => {
    const result = [];
    const elements = document.querySelectorAll('[class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [class*="mode"], [role="tab"], [role="radio"], [role="button"]');
    for (const el of elements) {
      const text = el.textContent?.trim();
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (text && text.length < 30 && visible) {
        const cls = el.className?.toString()?.substring(0, 50) || '';
        result.push({ text, cls, tag: el.tagName });
      }
    }
    return result;
  });
  console.log(`   Found ${switches.length} switch elements:`);
  switches.slice(0, 15).forEach(s => console.log(`   - "${s.text}" [${s.tag}] cls="${s.cls}"`));

  // DOCUMENT: Special modes (deep thinking, image)
  console.log('\n5. SPECIAL MODES (deep thinking, image generation)');
  const specialModes = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('*');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (!visible) continue;
      const text = el.textContent?.trim();
      const cls = el.className?.toString() || '';
      if (text && text.length < 40 && (text.includes('Deep') || text.includes('Image') || text.includes('Think') || text.includes('深度') || text.includes('图片') || text.includes('思考') || text.includes('Интенсивность') || text.includes('Intensity')) && !text.includes('{')) {
        result.push({ text: text.substring(0, 40), cls: cls.substring(0, 40) });
      }
    }
    return result;
  });
  console.log(`   Found ${specialModes.length} special mode elements:`);
  specialModes.slice(0, 15).forEach(m => console.log(`   - "${m.text}" cls="${m.cls}"`));

  // DOCUMENT: Effort levels
  console.log('\n6. EFFORT LEVELS');
  const effortLevels = await page.evaluate(() => {
    const result = [];
    const efforts = document.querySelectorAll('[class*="effort"]');
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
  console.log('\n7. PER-MODEL MODES (clicking each model)');
  const modelItems = await page.locator('div.model-item').all();
  const modelModes = {};
  for (let i = 0; i < modelItems.length; i++) {
    await modelItems[i].click();
    await page.waitForTimeout(2000);
    const modelName = await modelItems[i].querySelector('span.name')?.textContent?.trim();

    const available = await page.evaluate(() => {
      const els = document.querySelectorAll('[class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [role="tab"], [role="radio"]');
      return Array.from(els).filter(el => el.isVisible()).map(el => el.textContent?.trim()).filter(t => t && t.length < 20);
    });

    modelModes[modelName || `model${i}`] = available;
    console.log(`   "${modelName}":`, available);
  }

  await page.screenshot({ path: '/tmp/kimi-deep.png', fullPage: false });
  console.log('\n📸 Screenshot: /tmp/kimi-deep.png');

  await browser.close();
  return { models, switches, specialModes, effortLevels, modelModes };
}

researchKimi().catch(console.error);
