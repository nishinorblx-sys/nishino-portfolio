import asyncio
from pathlib import Path
from playwright.async_api import async_playwright
ROOT=Path('/mnt/data/foallow-v18')
async def main():
  async with async_playwright() as pw:
    browser=await pw.chromium.launch(headless=True,executable_path='/usr/bin/chromium',args=['--no-sandbox'])
    for width,height in [(1440,900),(390,844)]:
      page=await browser.new_page(viewport={'width':width,'height':height},device_scale_factor=1)
      err=[]
      page.on('pageerror',lambda error:err.append(str(error)))
      html=(ROOT/'proof.html').read_text()
      html=html.replace('<div class="ns-preloader" id="nsPreloader"','<div style="display:none" class="ns-preloader" id="nsPreloader"')
      html=html.replace('<script src="assets/data.js"></script>','').replace('<script src="assets/app.js"></script>','').replace('<script src="assets/motion.js"></script>','').replace('<script src="assets/sounds.js"></script>','').replace('<script src="assets/proof-code.js"></script>','')
      await page.set_content(html)
      await page.evaluate('''() => { window.fetch = async function(path) { const files = window._sampleFiles; const name = path.split('/').pop(); if (files[name]) return { ok:true, text: async () => files[name] }; return {ok:false}; }; }''')
      source={f.name:f.read_text() for f in (ROOT/'assets/code').glob('*.luau')}
      await page.evaluate('(src) => {window._sampleFiles = src}',source)
      for file in ['styles.css','motion.css','sounds.css','sections.css','foallow-theme.css','pricing-v10.css','proof-code.css']:
        await page.evaluate('css => {const tag=document.createElement("style");tag.textContent=css;document.head.appendChild(tag);}', (ROOT/'assets'/file).read_text().replace("@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Space+Grotesk:wght@400;500;600;700&display=swap');",''))
      await page.add_script_tag(content=(ROOT/'assets/data.js').read_text())
      app=(ROOT/'assets/app.js').read_text().replace("const currentPage = (() => {", "const currentPage = (() => {")
      start=app.index('const currentPage = (() => {')
      end=app.index('const svg =',start)
      app=app[:start]+"const currentPage = 'proof';\n"+app[end:]
      await page.add_script_tag(content=app)
      await page.add_script_tag(content=(ROOT/'assets/proof-code.js').read_text())
      await page.wait_for_selector('.proof-code-line')
      await page.wait_for_timeout(600)
      stats=await page.evaluate('''() => ({title:document.title,cardCount:document.querySelectorAll('.proof-code-item').length,lineCount:document.querySelector('.proof-code-lines').children.length,scrollWidth:document.documentElement.scrollWidth,innerWidth:innerWidth})''')
      print(width,stats,'errors',err)
      c=page.locator('.proof-code-item').first
      await c.locator('[data-action="expand"]').click()
      print('expanded',await c.locator('.proof-code-line').count())
      await c.locator('[data-action="expand"]').click()
      print('collapsed',await c.locator('.proof-code-line').count())
      await page.locator('.proof-code-section').scroll_into_view_if_needed()
      await page.screenshot(path=f'/mnt/data/foallow-v18-preview-{width}.png')
      await page.close()
    await browser.close()
asyncio.run(main())
