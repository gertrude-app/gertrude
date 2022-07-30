import { ComponentStory, ComponentMeta } from '@storybook/react';

import KeystrokesViewer from './KeystrokesViewer';

export default {
  title: 'KeystrokesViewer',
  component: KeystrokesViewer,
} as ComponentMeta<typeof KeystrokesViewer>;

const Template: ComponentStory<typeof KeystrokesViewer> = (args) => <KeystrokesViewer {...args} />;

export const Default = Template.bind({});
