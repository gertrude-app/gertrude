import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { ExtendedControlsDraft } from '#/components/pages/person-settings/IosSettingsPage.reducer';
import ExtendedSupervisionControls from './ExtendedSupervisionControls';
import { createIosSettingsFormState } from '#/components/pages/person-settings/IosSettingsPage.reducer';
import { iosDeviceSettingsExtendedControls } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Components/Person Settings/Extended Supervision Controls',
  component: ExtendedSupervisionControls,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

const blocker = iosDeviceSettingsExtendedControls.blocker!;
const configured = createIosSettingsFormState(blocker).extended!.draft;
const unrestricted = createIosSettingsFormState({
  ...blocker,
  extendedSupervisionControls: {},
}).extended!.draft;

export const States = {
  parameters: galleryParameters,
  render: function Render() {
    const [drafts, setDrafts] = React.useState<ExtendedControlsDraft[]>([
      unrestricted,
      configured,
      { ...unrestricted, whitelistedAppBundleIds: [], webAllowList: [] },
    ]);
    return (
      <StoryCanvas innerClassName="max-w-3xl">
        {[`No restrictions`, `Configured restrictions`, `Empty approval lists`].map(
          (title, index) => (
            <StorySection
              key={title}
              title={title}
              contentClassName="flex-col items-stretch"
            >
              <ExtendedSupervisionControls
                deviceType={index === 2 ? `iPad` : `iPhone`}
                draft={drafts[index]!}
                onChange={(values) =>
                  setDrafts((current) =>
                    current.map((draft, i) =>
                      i === index ? { ...draft, ...values } : draft,
                    ),
                  )
                }
              />
            </StorySection>
          ),
        )}
      </StoryCanvas>
    );
  },
};
