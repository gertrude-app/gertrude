import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import PlanChangeSummary from './PlanChangeSummary';
import { PLANS } from '#/lib/plans';

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
    title: `Full trial — keep Mac features`,
    props: { from: `medium`, to: `full`, trialFeatures: PLANS.full.features },
  },
  {
    title: `Full trial on Light — add Music and keep Mac features`,
    props: { from: `light`, to: `full`, trialFeatures: PLANS.full.features },
  },
  {
    title: `Downgrade — Medium to yearly Light`,
    props: { from: `medium`, to: `light` },
  },
  {
    title: `Legacy Full to Medium — same price, fewer features`,
    props: { from: `full`, to: `medium`, currentPriceInCents: 500 },
  },
  {
    title: `Full trial grace period`,
    props: {
      from: `medium`,
      to: `full`,
      trialFeatures: PLANS.full.features,
      trialFeatureHeading: `What you’ll keep after your grace period`,
    },
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
