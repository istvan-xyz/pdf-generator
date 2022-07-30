import { tmpdir } from 'os';
import { resolve } from 'path';
import express from 'express';
import morgan from 'morgan';
import puppeteer, { PaperFormat, PDFOptions } from 'puppeteer';

const port = +(process.env.PORT || 8080);
const host = '0.0.0.0';

const tempDir = tmpdir();

const sleep = async (milliseconds: number) =>
    new Promise((resolve) => {
        setTimeout(resolve, milliseconds);
    });

let pdfRequestId = 0;

const server = express();

server.use(express.urlencoded({ extended: true }));
server.use(express.json());

server.use(morgan(':method :url :status :res[content-length] - :response-time ms'));

server.get('/', (_, response) => {
    response.send('Ok');
});

server.get('/pdf', (request, response) => {
    pdfRequestId += 1;

    if (!request.query.url) {
        response.send('No URL');
        return;
    }

    (async () => {
        const path = resolve(tempDir, `${pdfRequestId}.pdf`);

        const browser = await puppeteer.launch({
            args: ['--no-sandbox', '--disable-setuid-sandbox'],
        });
        const page = await browser.newPage();

        // eslint-disable-next-line no-console
        console.log(`Process: ${request.query.url}`);

        if (request.query.baseAuthUser) {
            await page.authenticate({
                username: request.query.baseAuthUser as string,
                password: request.query.baseAuthPassword as string,
            });
        }

        if (request.query.cookies) {
            const cookies = JSON.parse(request.query.cookies as string);
            await page.setCookie(...cookies);
        }

        await page.goto(request.query.url as string); /* global window */
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        if ((await page.evaluate(async () => (window as any).IS_PAGE_READY)) === undefined) {
            await sleep(10_000);
        } else {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            while (!(await page.evaluate(async () => (window as any).IS_PAGE_READY))) {
                await sleep(100);
            }
        }

        /* global document */
        const title = await page.evaluate(() => document.title);
        const options: PDFOptions = {
            path,
            printBackground: true,
            format: 'A4' as PaperFormat,
        };

        if (request.query.headerTemplate) {
            options.headerTemplate = request.query.headerTemplate as string;
            options.displayHeaderFooter = true;
        }

        if (request.query.footerTemplate) {
            options.footerTemplate = request.query.footerTemplate as string;
            options.displayHeaderFooter = true;
        }

        if (request.query.margins) {
            options.margin = JSON.parse(request.query.margins as string);
        }

        await page.pdf(options);
        await browser.close();

        // eslint-disable-next-line no-console
        console.log(`Done: ${request.query.url}`);

        response.download(path, `${title}.pdf`);
    })().catch((pdfError) => {
        throw pdfError;
    });
});

server.disable('x-powered-by');

server.listen(port, host, () => {
    console.log(`Server listening ${host}:${port}`);
});
