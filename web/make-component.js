// @ts-check
const fs = require(`fs`);
const { red, green } = require(`x-chalk`);

const args = process.argv.slice(2);
if (args.length !== 2) {
  red(`Usage: make component [@dash|@marketing|@shared] RadButton`);
  process.exit(1);
}

const scope = args[0].replace(/^@/, ``);
if (![`dash`, `marketing`, `shared`].includes(scope)) {
  red(`Usage: make component [@dash|@marketing|@shared] RadButton`);
  process.exit(1);
}

const Component = args[1];
const componentFile = `import React from 'react';

type Props = {
  radProp?: string;
};

const ${Component}: React.FC<Props> = ({ radProp }) => <h1>${Component} placeholder {radProp}</h1>;

export default ${Component};
`;

const storyFile = `import { ComponentStory, ComponentMeta } from '@storybook/react';
import { ${Component} } from '@${scope}/components';

export default {
  title: \`${Component}\`,
  component: ${Component},
} as ComponentMeta<typeof ${Component}>;

const Template: ComponentStory<typeof ${Component}> = (args) => <${Component} {...args} />;

export const Default = Template.bind({});
Default.args = {}
`;

fs.writeFileSync(`./${scope}/components/src/${Component}.tsx`, componentFile);
fs.writeFileSync(`./storybook/src/${scope}/${Component}.stories.tsx`, storyFile);

const indexPath = `./${scope}/components/src/index.ts`;
const indexContents = fs.readFileSync(indexPath, `utf8`);
fs.writeFileSync(
  indexPath,
  `${indexContents}export { default as ${Component} } from './${Component}';\n`,
);

green(`Created component '${Component}'`);
