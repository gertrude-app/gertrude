import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { createServer } from 'node:http';
import { extname, join, normalize, sep } from 'node:path';

const mimeTypes = new Map([
  [`.css`, `text/css; charset=utf-8`],
  [`.gif`, `image/gif`],
  [`.html`, `text/html; charset=utf-8`],
  [`.ico`, `image/x-icon`],
  [`.jpg`, `image/jpeg`],
  [`.js`, `text/javascript; charset=utf-8`],
  [`.json`, `application/json; charset=utf-8`],
  [`.map`, `application/json; charset=utf-8`],
  [`.png`, `image/png`],
  [`.svg`, `image/svg+xml; charset=utf-8`],
  [`.webp`, `image/webp`],
  [`.woff`, `font/woff`],
  [`.woff2`, `font/woff2`],
]);

function safeJoin(root, urlPathname) {
  const relativePath = normalize(decodeURIComponent(urlPathname)).replace(/^[/\\]+/, ``);
  const filePath = join(root, relativePath || `index.html`);
  return filePath === root || filePath.startsWith(`${root}${sep}`) ? filePath : undefined;
}

async function fileExists(filePath) {
  try {
    return (await stat(filePath)).isFile();
  } catch {
    return false;
  }
}

export async function serveStorybook(root, { host = `127.0.0.1`, port = 0 } = {}) {
  const server = createServer(async (request, response) => {
    try {
      const requestUrl = new URL(request.url ?? `/`, `http://${host}`);
      const filePath = safeJoin(root, requestUrl.pathname);

      if (!filePath) {
        response.writeHead(403);
        response.end(`Forbidden`);
        return;
      }

      if (!(await fileExists(filePath))) {
        response.writeHead(404);
        response.end(`Not found`);
        return;
      }

      response.writeHead(200, {
        [`Content-Type`]: mimeTypes.get(extname(filePath)) ?? `application/octet-stream`,
      });
      createReadStream(filePath).pipe(response);
    } catch (error) {
      response.writeHead(500);
      response.end(error instanceof Error ? error.message : `Internal server error`);
    }
  });

  await new Promise((resolveServer, reject) => {
    server.once(`error`, reject);
    server.listen(port, host, () => {
      server.off(`error`, reject);
      resolveServer();
    });
  });
  return {
    baseUrl: `http://${host}:${server.address().port}`,
    close: () => new Promise((resolveServer) => server.close(resolveServer)),
  };
}
