import { ComponentStory, ComponentMeta } from '@storybook/react';
import UnlockRequestCard from './UnlockRequestCard';

export default {
  title: `UnlockRequestCard`,
  component: UnlockRequestCard,
} as ComponentMeta<typeof UnlockRequestCard>;

const Template: ComponentStory<typeof UnlockRequestCard> = (args) => <UnlockRequestCard {...args} />;

export const Default = Template.bind({});
