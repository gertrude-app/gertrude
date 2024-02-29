import MainHeader from 'site/components/MainHeader';
import cx from 'classnames';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const Container: React.FC<{ theme: `white` | `violet` }> = ({ theme }) => (
  <div
    className={cx(`w-screen h-screen`, theme === `white` ? `bg-white` : `bg-violet-500`)}
  >
    <MainHeader theme={theme} />
  </div>
);

const meta = {
  title: 'Site/MainHeader', // eslint-disable-line
  component: Container,
  parameters: {
    layout: `fullscreen`,
  },
} satisfies Meta<typeof MainHeader>;

type Story = StoryObj<typeof meta>;

export const WhiteTheme: Story = props({ theme: `white` });
export const VioletTheme: Story = props({ theme: `violet` });

export default meta;
