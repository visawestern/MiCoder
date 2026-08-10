import { chromium } from 'playwright';

async function deepResearchKimi() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('=== KIMI COMPLETE UI RESEARCH ===\n');
  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForTimeout(5000);

  // Enter chat
  const newChatBtn = page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first();
  if (await newChatBtn.count() > 0) {
    await newChatBtn.click();
    await page.waitForTimeout(5000);
  }

  console.log('1. ALL INTERACTIVE ELEMENTS (buttons, tabs, switches):');
  const allInteractive = await page.evaluate(() => {
    const result = [];
    const elements = document.querySelectorAll('button, [role="button"], [role="tab"], [role="radio"], [role="switch"], [role="checkbox"], a, [class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [class*="tab"], [class*="radio"]');
    for (const el of elements) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (!visible) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 60) {
        const cls = el.className?.toString()?.substring(0, 60) || '';
        const tag = el.tagName;
        const role = el.getAttribute('role') || '';
        result.push({ tag, role, text: text.substring(0, 50), cls });
      }
    }
    return result;
  });

  // Deduplicate
  const seen = new Set();
  const unique = allInteractive.filter(item => {
    const key = item.text + item.cls;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  unique.forEach((item, i) => console.log(`   ${i+1}. [${item.tag}${item.role ? '/' + item.role : ''}] "${item.text}" cls="${item.cls}"`));

  console.log('\n2. SIDEBAR NAVIGATION ITEMS:');
  const sidebarItems = await page.evaluate(() => {
    const result = [];
    const sidebar = document.querySelector('[class*="sidebar"], [class*="nav"], aside, nav');
    if (sidebar) {
      const items = sidebar.querySelectorAll('a, button, [role="button"], [class*="item"], [class*="nav"]');
      for (const el of items) {
        const rect = el.getBoundingClientRect();
        const visible = rect.width > 0 && rect.height > 0;
        if (visible) {
          const text = el.textContent?.trim();
          if (text && text.length > 1 && text.length < 40) {
            result.push(text.substring(0, 40));
          }
        }
      }
    }
    return [...new Set(result)];
  });
  sidebarItems.forEach((item, i) => console.log(`   ${i+1}. ${item}`));

  console.log('\n3. FEATURE MODES (Cluster, Slides, Deep Research):');
  const featureModes = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('*');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (!visible) continue;
      const text = el.textContent?.trim();
      if (text && text.length < 40 && (text.includes('Кластер') || text.includes('Cluster') || text.includes('Слайды') || text.includes('Slides') || text.includes('Глубок') || text.includes('Deep') || text.includes('Исследов') || text.includes('Research') || text.includes('Изображ') || text.includes('Image') || text.includes('Видео') || text.includes('Video')) && !text.includes('{')) {
        result.push(text.substring(0, 40));
      }
    }
    return [...new Set(result)];
  });
  featureModes.forEach(t => console.log(`   - ${t}`));

  console.log('\n4. MODEL-SPECIFIC SWITCHES (click each model):');
  const modelItems = await page.locator('div.model-item').all();
  const modelFeatures = {};
  for (let i = 0; i < modelItems.length; i++) {
    await modelItems[i].click();
    await page.waitForTimeout(2500);
    const modelName = await modelItems[i].querySelector('span.name')?.textContent?.trim();

    // Get all visible interactive elements
    const features = await page.evaluate(() => {
      const result = [];
      const all = document.querySelectorAll('button, [role="button"], [role="tab"], [role="switch"], [class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [class*="mode"]');
      for (const el of all) {
        const rect = el.getBoundingClientRect();
        const visible = rect.width > 0 && rect.height > 0;
        if (visible) {
          const text = el.textContent?.trim();
          if (text && text.length > 1 && text.length < 40) {
            const cls = el.className?.toString()?.substring(0, 50) || '';
            result.push({ text: text.substring(0, 40), cls });
          }
        }
      }
      return result;
    });

    modelFeatures[modelName || `model${i}`] = features;
    console.log(`   Model "${modelName}":`);
    features.slice(0, 10).forEach(f => console.log(`     - "${f.text}" cls="${f.cls}"`));
  }

  console.log('\n5. EFFORT LEVELS (click effort selector):');
  const effortEl = page.locator('[class*="effort"]').first();
  if (await effortEl.count() > 0) {
    await effortEl.click();
    await page.waitForTimeout(2500);
    const efforts = await page.evaluate(() => {
      const result = [];
      const all = document.querySelectorAll('[class*="effort"], [role="option"], [class*="option"]');
      for (const el of all) {
        const rect = el.getBoundingClientRect();
        const visible = rect.width > 0 && rect.height > 0;
        if (visible) {
          const text = el.textContent?.trim();
          if (text && text.length > 1 && text.length < 40) {
            result.push(text.substring(0, 40));
          }
        }
      }
      return [...new Set(result)];
    });
    efforts.forEach(e => console.log(`   - ${e}`));
  }

  await page.screenshot({ path: '/tmp/kimi-complete.png', fullPage: true });
  console.log('\n📸 Full screenshot: /tmp/kimi-complete.png');

  await browser.close();
  return { unique, sidebarItems, featureModes, modelFeatures };
}

async function deepResearchQwen() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('\n=== QWEN COMPLETE UI RESEARCH ===\n');
  await page.goto('https://chat.qwen.ai/', { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForTimeout(5000);

  // Enter chat
  const startBtn = page.locator('button').filter({ hasText: 'Начать' }).first();
  if (await startBtn.count() > 0) {
    await startBtn.click();
    await page.waitForTimeout(5000);
  }

  console.log('1. ALL INTERACTIVE ELEMENTS:');
  const allInteractive = await page.evaluate(() => {
    const result = [];
    const elements = document.querySelectorAll('button, [role="button"], [role="tab"], [role="radio"], [role="switch"], [role="checkbox"], a, [class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [class*="tab"], [class*="radio"], [class*="mode"]');
    for (const el of elements) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (!visible) continue;
      const text = el.textContent?.trim();
      if (text && text.length > 0 && text.length < 60) {
        const cls = el.className?.toString()?.substring(0, 60) || '';
        const tag = el.tagName;
        const role = el.getAttribute('role') || '';
        result.push({ tag, role, text: text.substring(0, 50), cls });
      }
    }
    return result;
  });

  const seen = new Set();
  const unique = allInteractive.filter(item => {
    const key = item.text + item.cls;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  unique.forEach((item, i) => console.log(`   ${i+1}. [${item.tag}${item.role ? '/' + item.role : ''}] "${item.text}" cls="${item.cls}"`));

  console.log('\n2. MODE SWITCHES (auto/think/fast/image):');
  const modeSwitches = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('[class*="mode"], [class*="switch"], [class*="toggle"], [role="tab"], [role="radio"]');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (visible) {
        const text = el.textContent?.trim();
        if (text && text.length > 1 && text.length < 40) {
          const cls = el.className?.toString()?.substring(0, 50) || '';
          result.push({ text: text.substring(0, 40), cls });
        }
      }
    }
    return result;
  });
  modeSwitches.forEach(m => console.log(`   - "${m.text}" cls="${m.cls}"`));

  console.log('\n3. IMAGE GENERATION FEATURES:');
  const imageFeatures = await page.evaluate(() => {
    const result = [];
    const all = document.querySelectorAll('*');
    for (const el of all) {
      const rect = el.getBoundingClientRect();
      const visible = rect.width > 0 && rect.height > 0;
      if (!visible) continue;
      const text = el.textContent?.trim();
      if (text && text.length < 40 && (text.includes('Image') || text.includes('image') || text.includes('изображ') || text.includes('图片') || text.includes('рисун') || text.includes('фото')) && !text.includes('{')) {
        result.push(text.substring(0, 40));
      }
    }
    return [...new Set(result)];
  });
  imageFeatures.forEach(t => console.log(`   - ${t}`));

  console.log('\n4. PER-MODEL FEATURES:');
  await page.locator('[class*="model-selector-text"]').first().click();
  await page.waitForTimeout(2500);
  const modelItems = await page.locator('[class*="model-item"]').all();
  const modelFeatures = {};
  for (let i = 0; i < modelItems.length; i++) {
    await modelItems[i].click();
    await page.waitForTimeout(2500);
    const modelName = await modelItems[i].querySelector('[class*="model-item-name"]')?.textContent?.trim();

    const features = await page.evaluate(() => {
      const result = [];
      const all = document.querySelectorAll('[class*="mode"], [class*="switch"], [class*="toggle"], [role="tab"], [role="radio"], [role="button"], button');
      for (const el of all) {
        const rect = el.getBoundingClientRect();
        const visible = rect.width > 0 && rect.height > 0;
        if (visible) {
          const text = el.textContent?.trim();
          if (text && text.length > 1 && text.length < 40) {
            const cls = el.className?.toString()?.substring(0, 50) || '';
            result.push({ text: text.substring(0, 40), cls });
          }
        }
      }
      return result;
    });

    modelFeatures[modelName || `model${i}`] = features;
    console.log(`   Model "${modelName}":`);
    features.slice(0, 10).forEach(f => console.log(`     - "${f.text}" cls="${f.cls}"`));
  }

  await page.screenshot({ path: '/tmp/qwen-complete.png', fullPage: true });
  console.log('\n📸 Full screenshot: /tmp/qwen-complete.png');

  await browser.close();
  return { unique, modeSwitches, imageFeatures, modelFeatures };
}

const kimi = await deepResearchKimi();
const qwen = await deepResearchQwen();

console.log('\n=== RESEARCH COMPLETE ===');
