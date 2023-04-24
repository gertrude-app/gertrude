/* eslint-disable */
// @ts-check
const fs = require(`node:fs`);
const exec = require(`x-exec`).default;

const MODULES = [`MenuBar`, `BlockedRequests`];
const WEBVIEW_DIR = `${__dirname}/../../swift/rewrite/Xcode/Gertrude/WebViews`;

fs.rmSync(`./dist`, { recursive: true, force: true });
fs.mkdirSync(`./dist`, { recursive: true });

MODULES.forEach((module) => {
  const fileContent = `
    import React from 'react';
    import ReactDOM from 'react-dom/client';
    import ${module} from './${module}/${module}';

    ReactDOM
      .createRoot(document.getElementById('app') as HTMLElement)
      .render(<${module} />);`;

  fs.writeFileSync(`./src/main.tsx`, fileContent);
  exec.out(`pnpm vite build --mode production --outDir ./dist/${module}`, __dirname);
  exec.out(`rm -rf ${WEBVIEW_DIR}/${module}`, __dirname);
  exec.exit(`cp -R ./dist/${module} ${WEBVIEW_DIR}/${module}`, __dirname);
});
