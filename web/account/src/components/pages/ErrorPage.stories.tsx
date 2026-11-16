import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import ErrorPage from './ErrorPage';

const meta = {
  title: 'Account/Pages/Error',
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <ErrorPage accountHref="/people" onReload={() => {}} />
    </StoryScreen>
  ),
};
