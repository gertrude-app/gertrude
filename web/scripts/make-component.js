// @ts-check
const fs = require(`fs`);
const { red, green } = require(`x-chalk`);

const args = process.argv.slice(2);
if (args.length !== 1) {
  red(`Usage: make component RadButton`);
  process.exit(1);
}

const Component = args[0];

const componentFile = `import React from 'react';

type Props = {
  className?: string;
};

const ${Component}: React.FC<Props> = ({ className }) => <h1>${Component} placeholder</h1>;

export default ${Component};
`;

const storyFile = `import { ComponentStory, ComponentMeta } from '@storybook/react';

import ${Component} from './${Component}';

export default {
  title: '${Component}',
  component: ${Component},
} as ComponentMeta<typeof ${Component}>;

const Template: ComponentStory<typeof ${Component}> = (args) => <${Component} {...args} />;

export const Default = Template.bind({});
`;

const dir = `./components/src/shared/dashboard/${Component}`;
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(`${dir}/${Component}.tsx`, componentFile);
fs.writeFileSync(`${dir}/${Component}.stories.tsx`, storyFile);
fs.writeFileSync(`${dir}/index.tsx`, `export { default } from './${Component}';`);

green(`Created component '${Component}`);
