import { ComponentMeta, ComponentStory } from '@storybook/react';
import GradientIcon, { IconsList } from './GradientIcon';

const GradientGrid: React.FC<{ size: `small` | `medium` | `large`; subtle: boolean }> = ({
  size,
  subtle,
}) => (
  <div className="flex flex-wrap max-w-lg m-2">
    {IconsList.map((icon) => (
      <div className="flex flex-col m-1 w-12 items-center">
        <GradientIcon icon={icon} size={size} key={icon} subtle={subtle} />
        <h2 className="text-[8px] text-gray-600 text-center">{icon}</h2>
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
  title: `Shared/GradientIcon`,
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
