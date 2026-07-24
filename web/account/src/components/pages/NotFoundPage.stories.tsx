import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import NotFoundPage from './NotFoundPage';

const meta = {
  title: 'Account/Pages/Not Found',
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <NotFoundPage accountHref="/people" />
    </StoryScreen>
  ),
};
