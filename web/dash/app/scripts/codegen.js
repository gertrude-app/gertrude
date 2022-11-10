#!/usr/bin/env node
// @ts-check
import fs from 'fs';
import glob from 'glob';
import xExec from 'x-exec';
import { c, log, green } from 'x-chalk';

// @ts-ignore
const exec = xExec.default;

const numSteps = 4;
let step = 1;
let success = true;
const CWD = process.cwd();

let endpoint = `http://127.0.0.1:8080/graphql/dashboard`;
const endpointIndex = process.argv.indexOf(`--endpoint`);
if (endpointIndex !== -1) {
  endpoint = process.argv[endpointIndex + 1];
}

const TYPES_PATH = `../types/src/api.ts`;
exec(`rm -f ${CWD}/${TYPES_PATH}`);
glob.sync(`${CWD}/**/__generated__/**/*`).forEach((path) => exec(`rm -f ${path}`));

log(c`{gray ${step++}/${numSteps}} {magenta Downloading schema...}`);
success = exec.out(
  `apollo client:download-schema --endpoint=${endpoint} ./schema.graphql`,
  CWD,
);

if (!success) {
  log(``);
  process.exit(1);
}

log(c`{gray ${step++}/${numSteps}} {magenta Downloading types...}`);
success = exec.out(
  `npx apollo client:codegen
    --passthroughCustomScalars
    --localSchemaFile=schema.graphql
    --globalTypesFile=${TYPES_PATH}
    --target=typescript
    --tagName=gql`.replace(/\n {4}/g, ` `),
  CWD,
);

if (!success) {
  log(``);
  process.exit(1);
}

log(c`{gray ${step++}/${numSteps}} {magenta Cleaning up...}`);
exec(`rm -f schema.graphql`, CWD);

exec(`rmdir __generated__`, CWD);

// prettier the codegen'd files
const PRETTIER_FORMAT = `${CWD}/../../node_modules/.bin/prettier --config ${CWD}/../../.prettierrc.json --write`;
exec.exit(`${PRETTIER_FORMAT} ${TYPES_PATH}`);
const typeDirs = glob.sync(`${CWD}/**/__generated__/`);
typeDirs.forEach((path) => exec.exit(`${PRETTIER_FORMAT} ${path}`));

log(c`{gray ${step++}/${numSteps}} {magenta Converting dates to string...}`);
convertDatesToString();

green(`\nCodegen complete!\n`);
process.exit(0);

function convertDatesToString() {
  const files = glob.sync(`${CWD}/**/__generated__/**/*.ts`);

  if (files.length === 0) {
    process.stderr.write(`No graphql files found by \`fix-timestamp-types.js\` script\n`);
    process.stderr.write(`Did you run the script from outside the project root?\n`);
    process.exit(1);
  }

  for (const file of files) {
    const content = fs.readFileSync(file, `utf-8`);
    fs.writeFileSync(file, content.replace(/: Date( \| null)?;/gm, `: string$1;`));
  }
}

// 👋 NOTE: the `make codegen` cmd also invokes ./fix-imports.sh, which for
// some reason doesn't work when i invoke it from node with exec()
