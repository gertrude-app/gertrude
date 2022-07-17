import { ComponentStory, ComponentMeta } from '@storybook/react';

import ColoredTag from './ColoredTag';

export default {
  title: `ColoredTag`,
  component: ColoredTag,
} as ComponentMeta<typeof ColoredTag>;

const All: React.FC = () => (
  <div className="space-y-6">
    <ColoredTag type="active" />
    <ColoredTag type="pending verification" />
    <ColoredTag type="verified" />
    <ColoredTag type="incomplete" />
    <ColoredTag type="incomplete expired" />
    <ColoredTag type="trialing" />
    <ColoredTag type="past due" />
    <ColoredTag type="canceled" />
    <ColoredTag type="unpaid" />
    <ColoredTag type="complementary" />
  </div>
);

const Template: ComponentStory<typeof ColoredTag> = () => <All />;

export const List = Template.bind({});
