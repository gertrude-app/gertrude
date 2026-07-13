import { CheckIcon } from 'lucide-react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Badge from './Badge';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const colors = [
  `neutral`,
  `violet`,
  `red`,
  `green`,
  `blue`,
  `yellow`,
  `beta`,
  `canary`,
] as const;
const sizes = [`xsmall`, `small`, `medium`, `large`] as const;
const labels: Record<(typeof colors)[number], string> = {
  neutral: `Draft`,
  violet: `New`,
  red: `Needs review`,
  green: `Active`,
  blue: `Managed`,
  yellow: `Waiting`,
  beta: `Beta`,
  canary: `Canary`,
};

const meta = {
  title: 'UI/Components/Badge',
  component: Badge,
  args: { children: `Badge` },
  argTypes: {
    children: { control: `text` },
    color: { options: colors, control: { type: `select` } },
    size: { options: sizes, control: { type: `inline-radio` } },
  },
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof Badge>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Colors: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      {colors.map((color) => (
        <StorySection key={color} title={color}>
          <Badge color={color}>{labels[color]}</Badge>
          <Badge color={color} icon={CheckIcon}>
            {labels[color]}
          </Badge>
        </StorySection>
      ))}
    </StoryCanvas>
  ),
};

export const Sizes: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      {sizes.map((size) => (
        <StorySection key={size} title={size}>
          <Badge size={size}>Neutral</Badge>
          <Badge size={size} icon={CheckIcon}>
            Neutral
          </Badge>
          <Badge size={size} color="beta">
            Beta
          </Badge>
          <Badge size={size} color="beta" icon={CheckIcon}>
            Beta
          </Badge>
        </StorySection>
      ))}
    </StoryCanvas>
  ),
};
