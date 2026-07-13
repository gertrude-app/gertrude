import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import PersonSettingsExpandableSection, {
  type PersonSettingsPreviewChip,
} from './PersonSettingsExpandableSection';

const monitoringPreviewChips = [
  {
    title: `Keylogging`,
    values: [{ text: `On`, color: `violet` }],
  },
  {
    title: `Screenshots`,
    values: [{ text: `Every 30s`, color: `violet` }],
  },
] satisfies PersonSettingsPreviewChip[];

const filteringPreviewChips = [
  {
    title: `Filter`,
    values: [{ text: `On`, color: `violet` }],
  },
  {
    title: `Keychains`,
    values: [
      { text: `School`, color: `violet` },
      { text: `Games`, color: `neutral` },
    ],
  },
] satisfies PersonSettingsPreviewChip[];

const manyPreviewChips = [
  {
    title: `Keylogging`,
    values: [{ text: `On`, color: `violet` }],
  },
  {
    title: `Screenshots`,
    values: [{ text: `Every 30s`, color: `violet` }],
  },
  {
    title: `Downtime`,
    values: [{ text: `Off`, color: `neutral` }],
  },
  {
    title: `Keychains`,
    values: [
      { text: `School`, color: `violet` },
      { text: `Games`, color: `neutral` },
    ],
  },
  {
    title: `Blocked groups`,
    values: [
      { text: `Social`, color: `violet` },
      { text: `Search`, color: `violet` },
      { text: `GIFs`, color: `neutral` },
    ],
  },
  {
    title: `Custom domains`,
    values: [{ text: `messages.google.com`, color: `neutral` }],
  },
] satisfies PersonSettingsPreviewChip[];

const meta = {
  title: 'Account/Components/Person Settings/Expandable Section',
  component: PersonSettingsExpandableSection,
  parameters: { layout: 'fullscreen', screenshotsAt: ['desktop'] },
};

export default meta;

export const States = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection title="Collapsed" contentClassName="flex-col items-stretch">
        <PersonSettingsExpandableSection
          title="Monitoring"
          previewChips={monitoringPreviewChips}
        >
          <p className="text-sm text-stone-600">Monitoring settings go here.</p>
        </PersonSettingsExpandableSection>
      </StorySection>
      <StorySection title="Expanded" contentClassName="flex-col items-stretch">
        <PersonSettingsExpandableSection
          title="Filtering"
          previewChips={filteringPreviewChips}
          defaultExpanded
        >
          <div className="flex flex-col gap-2 text-sm text-stone-600">
            <p>Keychains, schedules, and custom blocked domains go here.</p>
            <p>Click the section header to collapse it.</p>
          </div>
        </PersonSettingsExpandableSection>
      </StorySection>
      <StorySection title="With app icon" contentClassName="flex-col items-stretch">
        <PersonSettingsExpandableSection
          title="Safari"
          appIconUrl="/gertrude-blocker-app-icon.webp"
          previewChips={
            [
              {
                title: `Schedule`,
                values: [{ text: `Weekdays`, color: `violet` }],
              },
            ] satisfies PersonSettingsPreviewChip[]
          }
        >
          <p className="text-sm text-stone-600">App-specific settings go here.</p>
        </PersonSettingsExpandableSection>
      </StorySection>
      <StorySection title="Many chips" contentClassName="flex-col items-stretch">
        <PersonSettingsExpandableSection
          title="Mac settings"
          previewChips={manyPreviewChips}
        >
          <p className="text-sm text-stone-600">Lots of preview chips go here.</p>
        </PersonSettingsExpandableSection>
      </StorySection>
      <StorySection
        title="Many chips with app icon"
        contentClassName="flex-col items-stretch"
      >
        <PersonSettingsExpandableSection
          title="Minecraft"
          appIconUrl="/gertrude-blocker-app-icon.webp"
          previewChips={manyPreviewChips}
        >
          <p className="text-sm text-stone-600">Lots of app preview chips go here.</p>
        </PersonSettingsExpandableSection>
      </StorySection>
    </StoryCanvas>
  ),
};
