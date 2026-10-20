import asyncio
from pathlib import Path
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True,executable_path='/usr/bin/chromium',args=['--no-sandbox'])
        for width,height in [(1440,900),(390,844)]:
            page = await browser.new_page(viewport={'width':width,'height':height},device_scale_factor=1)
            errors=[]
            page.on('pageerror',lambda exc:errors.append(str(exc)))
            await page.goto('http://127.0.0.1:8791/proof.html',wait_until='domcontentloaded')
            await page.evaluate("sessionStorage.setItem('nishino-entered','yes')")
            await page.reload(wait_until='domcontentloaded')
            await page.wait_for_selector('.proof-code-line',timeout=10000)
            await page.wait_for_timeout(450)
            info=await page.evaluate("""() => ({ title:document.title,cards:document.querySelectorAll('.proof-code-item').length, firstSample:document.querySelector('.proof-code-lines')?.innerText.slice(0,100), scrollWidth:document.documentElement.scrollWidth,viewWidth:window.innerWidth, download:document.querySelector('.proof-code-link')?.getAttribute('href') })""")
            print('VIEWPORT',width,info,'ERRORS',errors)
            card=page.locator('.proof-code-item').first
            await card.locator('[data-action="expand"]').click()
            print('EXPANDED ROWS',await card.locator('.proof-code-line').count())
            await card.locator('[data-action="expand"]').click()
            print('COLLAPSED ROWS',await card.locator('.proof-code-line').count())
            await page.screenshot(path=f'/mnt/data/foallow-v18-proof-{width}.png',full_page=False)
            await page.close()
        await browser.close()

asyncio.run(main())
