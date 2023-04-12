#!/usr/bin/env node

'use strict';

const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto('http://www.heise.de');
  await page.screenshot({path: '/data/screenshot.png', fullPage: true});
  await browser.close();
})();
