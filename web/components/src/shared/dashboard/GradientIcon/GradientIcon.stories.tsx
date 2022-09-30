import { ComponentMeta, ComponentStory } from '@storybook/react';
import GradientIcon, { iconsList } from './GradientIcon';

const GradientGrid: React.FC<{ size: `small` | `medium` | `large`; subtle: boolean }> = ({
  size,
  subtle,
}) => (
  <div className="flex flex-wrap max-w-lg">
    {iconsList.map((icon) => (
      <div className="p-3">
        <GradientIcon icon={icon} size={size} key={icon} subtle={subtle} />
      </div>
    ))}
  </div>
);

const Template: ComponentStory<typeof GradientGrid> = (args) => (
  <GradientGrid {...args} />
);

export const Grid = Template.bind({});
Grid.args = {
  size: `small`,
  subtle: false,
};

export default {
  title: `Dashboard/GradientIcon`,
  component: GradientGrid,
  parameters: {
    layout: `fullscreen`,
  },
  argTypes: {
    size: {
      options: [`small`, `medium`, `large`],
      control: `radio`,
    },
  },
} as ComponentMeta<typeof GradientGrid>;
