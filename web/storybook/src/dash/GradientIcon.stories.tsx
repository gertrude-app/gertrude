import { GradientIcon, GRADIENT_ICONS } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../story-helpers';

const GradientGrid: React.FC<{ size: 'small' | 'medium' | 'large'; subtle: boolean }> = ({
  size,
  subtle,
}) => (
  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
    {GRADIENT_ICONS.map((icon) => (
      <div
        key={icon}
        className="flex flex-col bg-slate-100/40 px-4 py-8 items-center rounded-xl"
      >
        <GradientIcon icon={icon} size={size} key={icon} subtle={subtle} />
        <h2 className="text-xs whitespace-nowrap mt-2 font-mono text-slate-400 text-center">
          {icon}
        </h2>
      </div>
    ))}
  </div>
);

type Story = StoryObj<typeof meta>;

export const Grid: Story = props({
  size: `large`,
  subtle: false,
});

const meta = {
  title: 'Dashboard/Core/GradientIcon', // eslint-disable-line
  component: GradientGrid,
  argTypes: {
    size: {
      options: [`small`, `medium`, `large`],
      control: `radio`,
    },
  },
} satisfies Meta<typeof GradientGrid>;

export default meta;
