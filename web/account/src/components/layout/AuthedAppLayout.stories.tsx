import { PageHeading } from '@gertrude/ui';
import { galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import AuthedAppLayout from './AuthedAppLayout';
import DashboardPage from './DashboardPage';

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
    <AuthedAppLayout pathname="/requests/unlock" requestCount={4}>
      <DashboardPage
        heading={
          <PageHeading
            title="Dashboard"
            subtitle="A dashboard page inside the authenticated app layout."
          />
        }
      >
        <div className="rounded-xl border border-stone-200 bg-stone-50 p-6 text-stone-600">
          Staged dashboard content
        </div>
      </DashboardPage>
    </AuthedAppLayout>
  ),
};
