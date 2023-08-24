/* eslint-disable */
// @ts-check
const fs = require(`node:fs`);
const exec = require(`x-exec`).default;

const MODULES = [`MenuBar`, `BlockedRequests`, `Administrate`, `RequestSuspension`];
const WEBVIEW_DIR = `${__dirname}/../../swift/macapp/Xcode/Gertrude/WebViews`;

const isolated = process.argv[2];
if (isolated && !MODULES.includes(isolated)) {
  process.stderr.write(`\nModule must be one of: \`${MODULES.join(`\`, \``)}\`\n\n`);
  process.exit(1);
}

fs.rmSync(`./dist`, { recursive: true, force: true });
fs.mkdirSync(`./dist`, { recursive: true });

MODULES.forEach((module) => {
  if (isolated && module !== isolated) {
    return;
  }

  const fileContent = `
    import React from 'react';
    import ReactDOM from 'react-dom/client';
    import ${module} from './${module}/${module}';

    ReactDOM
      .createRoot(document.getElementById('app') as HTMLElement)
      .render(<${module} />);`;

  fs.writeFileSync(`./src/main.tsx`, fileContent);
  exec.out(`pnpm vite build --mode production --outDir ./dist/${module}`, __dirname);

  const indexHtml = fs.readFileSync(`./dist/${module}/index.html`, `utf-8`);
  const lightHtml = indexHtml.replace(`<body>`, `<body class="light">`);
  const darkHmtl = indexHtml.replace(`<body>`, `<body class="dark">`);
  fs.writeFileSync(`./dist/${module}/index.light.html`, lightHtml);
  fs.writeFileSync(`./dist/${module}/index.dark.html`, darkHmtl);
  exec.out(`rm ./dist/${module}/index.html`, __dirname);

  exec.out(`rm -rf ${WEBVIEW_DIR}/${module}`, __dirname);
  exec.exit(`cp -R ./dist/${module} ${WEBVIEW_DIR}/${module}`, __dirname);
});
