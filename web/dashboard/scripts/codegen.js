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

exec(`rm -f ${CWD}/../components/src/shared/dashboard/types/GraphQL.ts`);
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
  `npx apollo client:codegen
    --passthroughCustomScalars
    --localSchemaFile=schema.graphql
    --globalTypesFile=../components/src/shared/dashboard/types/GraphQL.ts
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
const PRETTIER_FORMAT = `${CWD}/../node_modules/.bin/prettier --config ${CWD}/../.prettierrc.json --write`;
exec.exit(`${PRETTIER_FORMAT} ../components/src/shared/dashboard/types/GraphQL.ts`);
const typeDirs = glob(`${CWD}/**/__generated__/`);
typeDirs.forEach((path) => exec.exit(`${PRETTIER_FORMAT} ${path}`));

log(c`{gray ${step++}/${numSteps}} {magenta Converting dates to string...}`);
convertDatesToString();

green(`\nCodegen complete!\n`);
process.exit(0);

function convertDatesToString() {
  const files = glob(`${CWD}/**/__generated__/**/*.ts`);

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
