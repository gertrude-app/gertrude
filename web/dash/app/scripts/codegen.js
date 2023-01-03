#!/usr/bin/env node

// @ts-check
import fs from 'fs';
import glob from 'glob';
import fetch from 'node-fetch';
import xExec from 'x-exec';

// @ts-ignore
const exec = xExec.default;

const CWD = process.cwd();
const APP_DIR = `${CWD}/src/pairql`;
const PKG_DIR = `${CWD}/../pairs/src`;

async function main() {
  clean();

  const { shared, pairs } = await getData();
  const globalNames = Object.keys(shared).filter((name) => name !== `ClientAuth`);
  globalNames.push(`SuccessOutput`);

  let sharedFile = Object.values(shared).join(`\n\n`);
  sharedFile = sortShared(spaced(SUCCESS_OUTPUT, sharedFile));
  fs.writeFileSync(`${PKG_DIR}/shared.ts`, sharedFile);

  const indexLines = [
    `export type { PqlError } from './Result';`,
    `export { default as Result } from './Result';`,
    `export * from './shared';`,
  ];

  const ordered = Object.entries(pairs).sort(([a], [b]) => a.localeCompare(b));

  for (const [pairName, { pair }] of ordered) {
    const globals /** @type string[] */ = [];
    for (const typeName of globalNames) {
      const regex = new RegExp(`\\b${typeName}\\b`);
      if (
        pair.match(regex) &&
        !pair.includes(`'${typeName}'`) &&
        !pair.includes(`interface ${typeName}`)
      ) {
        globals.push(typeName);
      }
    }

    let sharedImport = ``;
    if (globals.length > 0) {
      sharedImport = `import type { ${globals.join(`, `)} } from '../shared';\n`;
    }
    fs.writeFileSync(
      `${PKG_DIR}/pairs/${pairName}.ts`,
      `// auto-generated, do not edit\n` + spaced(sharedImport, expand(pair)),
    );

    indexLines.push(`export * from './pairs/${pairName}';`);
  }

  fs.writeFileSync(`${PKG_DIR}/index.ts`, indexLines.join(`\n`));

  const liveClientMethods /** @type string[] */ = [];
  const throwingClientLines /** @type string[] */ = [];

  for (const [pairName, { fetcher }] of ordered) {
    const methodName = uncapitalize(pairName).replace(/_.*$/, ``);
    liveClientMethods.push(fetcher);
    throwingClientLines.push(
      `  ${methodName}: () => { throw new Error(\`ApiClient.${methodName}() not implemented\`); },`,
    );
  }

  const clientFileLines = [
    `// auto-generated, do not edit`,
    `import { ClientAuth } from '@dash/pairs';`,
    `import type * as T from '@dash/pairs'`,
    `import { query } from './query';`,
    ``,
    `export const liveClient = {`,
    liveClientMethods.join(`,\n\n`),
    `};`,
    ``,
    `export type ApiClient = typeof liveClient;`,
    ``,
    `export const throwingClient: ApiClient = {`,
    ...throwingClientLines,
    `};`,
    ``,
  ];

  fs.writeFileSync(`${APP_DIR}/client.ts`, clientFileLines.join(`\n`));

  // prettier the codegen'd files
  exec.exit(`${PRETTIER_FORMAT} ${APP_DIR}/*.ts`);
  exec.exit(`${PRETTIER_FORMAT} ${PKG_DIR}/*.ts`);
  exec.exit(`${PRETTIER_FORMAT} ${PKG_DIR}/pairs/*.ts`);
}

main();

function clean() {
  exec(`rm -rf ${PKG_DIR}/pairs`);
  exec(`rm -f ${PKG_DIR}/index.ts`);
  exec(`mkdir -p ${PKG_DIR}/pairs`);
}

/**
 * @returns {Promise<{
 *   shared: Record<string, string>;
 *   pairs: Record<string, { pair: string, fetcher: string }>;
 * }>}
 */
async function getData() {
  let endpoint = `http://127.0.0.1:8082/dashboard-ts-codegen`;
  const endpointIndex = process.argv.indexOf(`--endpoint`);
  if (endpointIndex !== -1) {
    endpoint = process.argv[endpointIndex + 1];
  }

  const res = await fetch(endpoint);

  /** @type {any} */
  const json = await res.json();
  return json;
}

/**
 * @param {string} s
 * @returns {string}
 */
function uncapitalize(s) {
  return s.charAt(0).toLowerCase() + s.slice(1);
}

/**
 * @param {string[]} strings
 * @returns {string}
 */
function spaced(...strings) {
  return strings.join(`\n\n`);
}

/**
 * @param {string} paircode
 * @returns {string}
 */
function expand(paircode) {
  return paircode.replace(/Array<{ /g, `Array<{\n`).replace(/{ /g, `{\n`);
}

/**
 * @param {string} code
 * @returns {string}
 */
function sortShared(code) {
  const parts = code.split(`\n\n`).map((chunk) => {
    const lines = chunk.split(`\n`);
    const firstLine = lines[0];
    const typeName = firstLine.replace(/export (:?type|interface|enum) ([^ ]+) .*/, `$2`);
    return { typeName, chunk };
  });
  parts.sort((a, b) => a.typeName.localeCompare(b.typeName));
  return parts.map((p) => p.chunk).join(`\n\n`);
}

const SUCCESS_OUTPUT = `
export interface SuccessOutput {
  success: boolean;
}
`.trim();

const PRETTIER_FORMAT = [
  `${CWD}/../../node_modules/.bin/prettier`,
  `--config`,
  `${CWD}/../../.prettierrc.json`,
  `--write`,
].join(` `);
