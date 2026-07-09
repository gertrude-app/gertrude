import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import AuthedAppLayout from './AuthedAppLayout';

const meta = {
  title: 'Account/Components/Layout/Authed App Layout',
  component: AuthedAppLayout,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const WithRequestBadge = {
  name: 'With request badge',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <AuthedAppLayout pathname="/requests/unlock" requestCount={4}>
        <div className="min-h-screen bg-white p-8 text-stone-600">
          Staged dashboard content
        </div>
      </AuthedAppLayout>
    </StoryScreen>
  ),
};
