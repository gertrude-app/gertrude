import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import SetupChecklist from './SetupChecklist';

const noop = (): void => {};

const meta = {
  title: 'Account/Components/Onboarding/Setup Checklist',
  component: SetupChecklist,
  parameters: { layout: 'fullscreen', screenshotsAt: ['desktop'] },
};

export default meta;

export const States = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Person added" contentClassName="items-start">
        <div className="w-58">
          <SetupChecklist
            selectedApps={[`mac`, `music`]}
            completedSteps={[`person`]}
            onSelectStep={noop}
          />
        </div>
      </StorySection>
      <StorySection title="Mac connected" contentClassName="items-start">
        <div className="w-58">
          <SetupChecklist
            selectedApps={[`mac`, `music`]}
            completedSteps={[`person`, `mac`]}
            onSelectStep={noop}
          />
        </div>
      </StorySection>
      <StorySection title="Collapsed" contentClassName="items-start">
        <div className="w-58">
          <SetupChecklist
            selectedApps={[`mac`, `music`]}
            completedSteps={[`person`]}
            onSelectStep={noop}
            defaultExpanded={false}
          />
        </div>
      </StorySection>
      <StorySection title="Apps undecided" contentClassName="items-start">
        <div className="w-58">
          <SetupChecklist
            selectedApps={[]}
            completedSteps={[`person`]}
            onSelectStep={noop}
          />
        </div>
      </StorySection>
    </StoryCanvas>
  ),
};
