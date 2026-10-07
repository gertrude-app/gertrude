import { StoryCanvas, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps } from 'react';
import KeychainEditorModal from './KeychainEditorModal';

const meta = {
  title: 'Account/Keychains/Keychain Editor',
  component: KeychainEditorModal,
  parameters: {
    layout: `fullscreen`,
    screenshotsAt: [`mobile`, `desktop`],
    ...galleryParameters,
  },
  args: {
    saving: false,
    onClose: () => {},
    onSave: () => Promise.resolve(),
  },
  render: (args: ComponentProps<typeof KeychainEditorModal>) => (
    <StoryCanvas>
      <KeychainEditorModal {...args} />
    </StoryCanvas>
  ),
};

export default meta;

export const Create = {};

export const Edit = {
  args: {
    keychain: {
      name: `School websites`,
      description: `Sites used for homework and class projects.`,
    },
  },
};

export const Saving = {
  args: {
    ...Edit.args,
    saving: true,
  },
};
