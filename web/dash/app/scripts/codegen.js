#!/usr/bin/env node

// @ts-check
import fs from 'fs';
import glob from 'glob';
import fetch from 'node-fetch';
import xExec from 'x-exec';

// @ts-ignore
const exec = xExec.default;

async function main() {
  const CWD = process.cwd();
  const PQL_DIR = `${CWD}/src/pairql`;

  // clean out dir
  exec(`rm -rf ${PQL_DIR}/pairs`);
  const toDelete = glob
    .sync(`${PQL_DIR}/*.ts`)
    .filter((f) => !f.endsWith(`query.ts`) && !f.endsWith(`noopClient.ts`));
  for (const file of toDelete) {
    fs.unlinkSync(file);
  }
  exec(`mkdir -p ${PQL_DIR}/pairs`);

  const { shared, pairs } = await getData();
  const sharedTypeNames = Object.keys(shared).filter((name) => name !== `ClientAuth`);
  sharedTypeNames.push(`SuccessOutput`);

  const sharedFile = Object.values(shared).join(`\n\n`);
  fs.writeFileSync(`${PQL_DIR}/shared.ts`, spaced(SUCCESS_OUTPUT, sharedFile));

  for (const [pairName, paircode] of Object.entries(pairs)) {
    const additionalImports /** @type string[] */ = [];
    for (const typeName of sharedTypeNames) {
      if (paircode.includes(typeName)) {
        additionalImports.push(typeName);
      }
    }
    let sharedImport = ``;
    if (additionalImports.length > 0) {
      sharedImport = `import type { ${additionalImports.join(
        `, `,
      )} } from '../shared';\n`;
    }
    fs.writeFileSync(
      `${PQL_DIR}/pairs/${pairName}.ts`,
      `// auto-generated, do not edit\n` +
        sharedImport +
        spaced(PAIR_IMPORTS, expand(paircode)),
    );
  }

  const indexLines /** @type string[] */ = [];
  for (const pairName of Object.keys(pairs)) {
    indexLines.push(`export * from './${pairName}';`);
  }
  fs.writeFileSync(`${PQL_DIR}/pairs/index.ts`, indexLines.join(`\n`));

  const interfaceLines /** @type string[] */ = [];
  const liveClientLines /** @type string[] */ = [];
  const throwingClientLines /** @type string[] */ = [];
  for (const pairName of Object.keys(pairs)) {
    const methodName = uncapitalize(pairName).replace(/_.*$/, ``);
    interfaceLines.push(`  ${methodName}: typeof Pql.${pairName}.fetch;`);
    liveClientLines.push(`  ${methodName}: Pql.${pairName}.fetch,`);
    throwingClientLines.push(
      `  ${methodName}: () => { throw new Error('Apiclient.${methodName}() not implemented'); },`,
    );
  }

  const clientFileLines = [
    `// auto-generated, do not edit`,
    `import * as Pql from './pairs';`,
    ``,
    `export interface ApiClient {`,
    ...interfaceLines,
    `};`,
    ``,
    `const liveClient: ApiClient = {`,
    ...liveClientLines,
    `};`,
    ``,
    `export const throwingClient: ApiClient = {`,
    ...throwingClientLines,
    `};`,
    ``,
    `export default liveClient;`,
  ];
  fs.writeFileSync(`${PQL_DIR}/client.ts`, clientFileLines.join(`\n`));

  // prettier the codegen'd files
  const PRETTIER_FORMAT = `${CWD}/../../node_modules/.bin/prettier --config ${CWD}/../../.prettierrc.json --write`;
  exec.exit(`${PRETTIER_FORMAT} ${PQL_DIR}/*.ts`);
  exec.exit(`${PRETTIER_FORMAT} ${PQL_DIR}/pairs/*.ts`);
}

main();

/**
 * @returns {Promise<{
 *   shared: Record<string, string>;
 *   pairs: Record<string, string>;
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

const PAIR_IMPORTS = `
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';
`.trim();

const SUCCESS_OUTPUT = `
export interface SuccessOutput {
  success: boolean;
}
`.trim();
