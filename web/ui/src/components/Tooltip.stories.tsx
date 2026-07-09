import { InfoIcon, LockIcon, Trash2Icon } from 'lucide-react';
import { fn } from 'storybook/test';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { FC } from 'react';
import Button from './Button';
import Tooltip, { TooltipProvider } from './Tooltip';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const tooltipAction = fn();
const sides = [`top`, `right`, `bottom`, `left`] as const;
const aligns = [`start`, `center`, `end`] as const;

const meta = {
  title: 'UI/Components/Tooltip',
  component: Tooltip,
  args: {
    content: `Tooltip content should clarify, not carry essential information.`,
    open: true,
    children: (
      <Button type="button" onClick={tooltipAction}>
        Tooltip target
      </Button>
    ),
  },
  argTypes: {
    content: { control: `text` },
    side: { options: sides, control: { type: `inline-radio` } },
    align: { options: aligns, control: { type: `inline-radio` } },
    showArrow: { control: `boolean` },
    disabled: { control: `boolean` },
    open: { control: `boolean` },
    alignOffset: { control: false },
    children: { control: false },
    closeDelay: { control: false },
    contentClassName: { control: false },
    defaultOpen: { control: false },
    delay: { control: false },
    onOpenChange: { control: false },
    positionerClassName: { control: false },
    sideOffset: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Tooltip>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Basic: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Common tooltips">
        <TooltipProvider>
          <div className="flex flex-wrap items-center gap-3">
            <Tooltip content="Private rules are visible only to admins.">
              <Button
                type="button"
                onClick={tooltipAction}
                icon={LockIcon}
                ariaLabel="Private rules"
              />
            </Tooltip>
            <Tooltip content="Deletes this item after confirmation." side="bottom">
              <Button
                type="button"
                onClick={tooltipAction}
                icon={Trash2Icon}
                ariaLabel="Delete item"
              />
            </Tooltip>
            <Tooltip content="Tooltip content should clarify, not carry essential information.">
              <Button
                type="button"
                onClick={tooltipAction}
                icon={InfoIcon}
                ariaLabel="Tooltip guidance"
              />
            </Tooltip>
            <Tooltip content="Button triggers work too.">
              <Button type="button" onClick={tooltipAction}>
                Hover or focus me
              </Button>
            </Tooltip>
          </div>
        </TooltipProvider>
      </StorySection>
    </StoryCanvas>
  ),
};

export const Placements: Story = {
  parameters: { ...galleryParameters, screenshotsAt: [`desktop`] },
  render: () => (
    <StoryCanvas>
      <StorySection title="Placements" contentClassName="justify-center">
        <TooltipProvider delay={0} closeDelay={0}>
          <div className="grid grid-cols-3 grid-rows-3 items-center justify-items-center gap-5 py-10">
            <div />
            <PlacementButton side="top" />
            <div />
            <PlacementButton side="left" />
            <div className="rounded-2xl border border-stone-200 bg-stone-50 px-5 py-4 text-center text-sm text-stone-500">
              Sides
            </div>
            <PlacementButton side="right" />
            <div />
            <PlacementButton side="bottom" />
            <div />
          </div>
        </TooltipProvider>
      </StorySection>
    </StoryCanvas>
  ),
};

type PlacementButtonProps = {
  side: (typeof sides)[number];
};

const PlacementButton: FC<PlacementButtonProps> = ({ side }) => (
  <Tooltip content={`Tooltip on the ${side}`} side={side} open>
    <button
      type="button"
      aria-label={`Show ${side} tooltip`}
      className="rounded-full border border-stone-200 bg-white px-4 py-2 text-sm font-medium capitalize text-stone-800 shadow-sm shadow-stone-300/40 transition hover:border-stone-300 hover:bg-stone-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-violet-400"
    >
      {side}
    </button>
  </Tooltip>
);
