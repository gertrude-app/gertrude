import { PillBadge } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Core/PillBadge', // eslint-disable-line
  component: PillBadge,
} as ComponentMeta<typeof PillBadge>;

const All: React.FC = () => (
  <div className="space-y-6">
    <PillBadge type="info">info</PillBadge>
    <PillBadge type="blue">blue</PillBadge>
    <PillBadge type="ok">ok</PillBadge>
    <PillBadge type="green">green standard</PillBadge>
    <PillBadge type="green" small>
      green small
    </PillBadge>
    <PillBadge type="warning">warning standard</PillBadge>
    <PillBadge type="warning" small>
      warning small
    </PillBadge>
    <PillBadge type="yellow">yellow</PillBadge>
    <PillBadge type="error">error</PillBadge>
    <PillBadge type="red">red</PillBadge>
  </div>
);

const Template: ComponentStory<typeof PillBadge> = () => <All />;

// @screenshot: xs
export const List = Template.bind({});
