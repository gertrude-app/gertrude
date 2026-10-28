import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import PlanChangeSummary from './PlanChangeSummary';

const meta = {
  title: 'Account/Components/Billing/Plan Change Summary',
  component: PlanChangeSummary,
  parameters: { layout: 'fullscreen' },
};

export default meta;

const cases: {
  title: string;
  props: React.ComponentProps<typeof PlanChangeSummary>;
}[] = [
  {
    title: `Upgrade — Medium to Full`,
    props: { from: `medium`, to: `full` },
  },
  {
    title: `Upgrade — Light to Full`,
    props: { from: `light`, to: `full` },
  },
  {
    title: `Downgrade — Medium to yearly Light`,
    props: { from: `medium`, to: `light` },
  },
  {
    title: `Legacy Full to Medium — same price, fewer features`,
    props: { from: `full`, to: `medium`, currentPriceInCents: 500 },
  },
];

export const Assortment = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryCanvas className="max-md:p-4">
      <div className="grid items-start gap-8 md:grid-cols-2">
        {cases.map(({ title, props }) => (
          <StorySection
            key={title}
            title={title}
            contentClassName="block rounded-2xl bg-white p-5"
          >
            <PlanChangeSummary {...props} />
          </StorySection>
        ))}
      </div>
    </StoryCanvas>
  ),
};
