/**
 * Copyright 2017 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
	const browser = await puppeteer.launch({headless: "new"});
	const page = await browser.newPage();
	await page.goto(`file:${path.join(__dirname, '_site/index.html')}`, {
		waitUntil: 'networkidle2',
	});
	// page.pdf() is currently supported only in headless mode.
	// @see https://bugs.chromium.org/p/chromium/issues/detail?id=753118
	await page.pdf({
		path: '_site/resume.pdf',
		format: 'letter',
		omitBackground: true,
		printBackground: true
	});

	await browser.close();
})();