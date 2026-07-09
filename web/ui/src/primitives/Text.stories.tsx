import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Card from './Card';
import Divider from './Divider';
import Text, { type TextVariant, textVariantClasses } from './Text';
import VStack from './VStack';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const meta = {
  title: 'UI/Primitives/Text',
  component: Text,
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof Text>;

export default meta;

type Story = StoryObj<typeof meta>;

type TextVariantExample = {
  variant: TextVariant;
  sample: React.ReactNode;
  note: string;
};

type TextVariantGroup = {
  title: string;
  examples: TextVariantExample[];
};

const variantGroups: TextVariantGroup[] = [
  {
    title: `Hierarchy`,
    examples: [
      {
        variant: `display`,
        sample: `People`,
        note: `Top-level display text`,
      },
      {
        variant: `title`,
        sample: `Notification settings`,
        note: `Panel and screen titles`,
      },
      {
        variant: `heading`,
        sample: `Mac settings`,
        note: `Card and section headings`,
      },
      {
        variant: `subheading`,
        sample: `We're biased, but we think they're pretty great.`,
        note: `Large supporting text below a display heading`,
      },
    ],
  },
  {
    title: `Body`,
    examples: [
      {
        variant: `bodyLargeStrong`,
        sample: `Sarah's MacBook Air`,
        note: `Prominent row titles`,
      },
      {
        variant: `bodyLarge`,
        sample: `Adult Content`,
        note: `Prominent body text without heading weight`,
      },
      {
        variant: `bodyStrong`,
        sample: `Sarah's MacBook Air`,
        note: `Primary text in dense rows`,
      },
      {
        variant: `body`,
        sample: `Screenshots, keylogging, and app rules are configured here.`,
        note: `Default supporting text`,
      },
      {
        variant: `bodySubtle`,
        sample: `Custom notifications for different types of events.`,
        note: `Secondary body text`,
      },
      {
        variant: `prose`,
        sample: `Gertrude will include this context in the notification preview so parents can quickly understand what happened.`,
        note: `Longer paragraphs with more leading`,
      },
      {
        variant: `proseSubtle`,
        sample: `Install the app, then create a private topic for Gertrude notifications.`,
        note: `Secondary longer paragraphs`,
      },
      {
        variant: `bodyMuted`,
        sample: `No activity to review.`,
        note: `Quiet helper and empty-state text`,
      },
    ],
  },
  {
    title: `Small`,
    examples: [
      {
        variant: `label`,
        sample: `Notification methods`,
        note: `Small grouped labels`,
      },
      {
        variant: `captionStrong`,
        sample: `Good News`,
        note: `Primary text inside tiny dense UI`,
      },
      {
        variant: `captionSubtleStrong`,
        sample: `Already added`,
        note: `Secondary labels with emphasis`,
      },
      {
        variant: `caption`,
        sample: `Today at 8:41 AM`,
        note: `Metadata and secondary row text`,
      },
      {
        variant: `captionSubtle`,
        sample: `15 minutes`,
        note: `Secondary metadata`,
      },
      {
        variant: `captionMuted`,
        sample: `MacBook Air • macOS 15.2`,
        note: `Quiet metadata`,
      },
      {
        variant: `warning`,
        sample: `The user can delete apps from their iPhone.`,
        note: `Warning callouts`,
      },
      {
        variant: `error`,
        sample: `Enter a valid email address.`,
        note: `Validation and error text`,
      },
      {
        variant: `code`,
        sample: `gertrude-family-alerts`,
        note: `Technical values and copyable tokens`,
      },
    ],
  },
];

const VariantCard: React.FC<TextVariantExample> = ({ variant, sample, note }) => (
  <Card className="min-w-0" padding={3}>
    <VStack gap={2}>
      <code className="w-fit rounded-md border border-stone-200 bg-stone-50 px-1.5 py-0.5 text-[11px] text-stone-600">
        {variant}
      </code>
      <Text as="div" variant={variant}>
        {sample}
      </Text>
      <Divider />
      <VStack gap={1}>
        <Text as="div" variant="captionMuted">
          {note}
        </Text>
        <code className="break-all text-[11px] leading-4 text-stone-400">
          {textVariantClasses[variant]}
        </code>
      </VStack>
    </VStack>
  </Card>
);

export const Presets: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      {variantGroups.map((group) => (
        <StorySection
          key={group.title}
          title={group.title}
          contentClassName="grid w-full grid-cols-1 items-stretch gap-3 md:grid-cols-2 lg:grid-cols-3"
        >
          {group.examples.map((example) => (
            <VariantCard key={example.variant} {...example} />
          ))}
        </StorySection>
      ))}
    </StoryCanvas>
  ),
};

export const TextOverflow: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Overflow helpers"
        contentClassName="grid w-full gap-3 md:grid-cols-2"
      >
        <Card padding={3}>
          <VStack gap={2}>
            <code className="w-fit rounded-md border border-stone-200 bg-stone-50 px-1.5 py-0.5 text-[11px] text-stone-600">
              truncate
            </code>
            <Text as="div" variant="bodyStrong" truncate>
              A very long device name that should stay on one line inside a dense row
            </Text>
          </VStack>
        </Card>
        <Card padding={3}>
          <VStack gap={2}>
            <code className="w-fit rounded-md border border-stone-200 bg-stone-50 px-1.5 py-0.5 text-[11px] text-stone-600">
              lineClamp={2}
            </code>
            <Text as="p" variant="prose" lineClamp={2}>
              This longer paragraph represents helper copy or preview text that should
              show enough context to be useful, but not grow a compact component beyond
              its intended height.
            </Text>
          </VStack>
        </Card>
      </StorySection>
    </StoryCanvas>
  ),
};
