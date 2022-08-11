#!/usr/bin/env node
// @ts-check
const fs = require(`fs`);
const { sync: glob } = require(`glob`);
const exec = require(`x-exec`).default;
const { c, log, green } = require(`x-chalk`);

const numSteps = 4;
let step = 1;
let success = true;
const CWD = process.cwd();

let endpoint = `http://127.0.0.1:8080/graphql/dashboard`;
const endpointIndex = process.argv.indexOf(`--endpoint`);
if (endpointIndex !== -1) {
  endpoint = process.argv[endpointIndex + 1];
}

glob(`${CWD}/**/__generated__/**/*`).forEach((path) => exec(`rm -f ${path}`));

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
  `npx apollo client:codegen --passthroughCustomScalars --localSchemaFile=schema.graphql --target=typescript --tagName=gql`,
  CWD,
);

if (!success) {
  log(``);
  process.exit(1);
}

log(c`{gray ${step++}/${numSteps}} {magenta Cleaning up...}`);
exec(`rm -f schema.graphql`, CWD);

const typeDirs = glob(`${CWD}/**/__generated__/`);
typeDirs.forEach((path) => {
  const NPM_BIN = `${CWD}/../node_modules/.bin`;
  exec.exit(`${NPM_BIN}/prettier --config ${CWD}/../.prettierrc.json --write ${path}`);
});

log(c`{gray ${step++}/${numSteps}} {magenta Converting dates to string...}`);
convertDatesToString();

green(`\nCodegen complete!\n`);
process.exit(0);

function convertDatesToString() {
  const files = glob(`${CWD}/**/__generated__/**/*.ts`);

  if (files.length === 0) {
    console.error(`No graphql files found by \`fix-timestamp-types.js\` script`);
    console.error(`Did you run the script from somewhere other than the project root?`);
    process.exit(1);
  }

  for (const file of files) {
    const content = fs.readFileSync(file, `utf-8`);
    fs.writeFileSync(file, content.replace(/: Date( \| null)?;/gm, `: string$1;`));
  }
}
