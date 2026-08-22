import { StoryCanvas, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { KeychainKey } from '#/components/types';
import CreateKeySlideOver, { EditKeySlideOver } from './KeyEditorSlideOver';

const apps = [
  { name: `Brave Browser`, slug: `brave`, bundleId: `com.brave.Browser` },
  {
    name: `Google Chrome`,
    slug: `chrome`,
    bundleId: `com.google.Chrome`,
    appIconUrl: `/example-app-icons/chrome.webp`,
  },
  {
    name: `Minecraft`,
    slug: `minecraft`,
    bundleId: `com.mojang.minecraftlauncher`,
    appIconUrl: `/example-app-icons/minecraft.webp`,
  },
  {
    name: `Safari`,
    slug: `safari`,
    bundleId: `com.apple.Safari`,
    appIconUrl: `/example-app-icons/safari.webp`,
  },
  {
    name: `Slack`,
    slug: `slack`,
    bundleId: `com.tinyspeck.slackmacgap`,
    appIconUrl: `/slack-logo.png`,
  },
  { name: `Zoom`, slug: `zoom`, bundleId: `us.zoom.xos` },
];

const existingKey: KeychainKey = {
  id: `school-key`,
  key: {
    type: `domain`,
    domain: `school.example.com`,
    scope: { type: `webBrowsers` },
  },
  comment: `Student portal`,
  expiration: `2027-09-14T20:30:00.000Z`,
};

const advancedKey: KeychainKey = {
  id: `classroom-device`,
  key: {
    type: `ipAddress`,
    ipAddress: `192.0.2.24`,
    scope: { type: `unrestricted` },
  },
  comment: `Local classroom device`,
};

const meta = {
  title: 'Account/Keychains/Key Editor',
  component: CreateKeySlideOver,
  parameters: {
    layout: `fullscreen`,
    screenshotsAt: [`mobile`, `desktop`],
  },
};

export default meta;

const background = (
  <StoryCanvas>
    <div className="mx-auto max-w-5xl px-6 py-20">
      <div className="h-24 rounded-2xl border border-stone-200 bg-white shadow-sm" />
    </div>
  </StoryCanvas>
);

const editorProps = {
  open: true,
  apps,
  saving: false,
  onOpenChange: () => {},
  onSave: () => Promise.resolve(),
};

const editProps = {
  ...editorProps,
  deleting: false,
  onDelete: () => Promise.resolve(),
};

export const Create = {
  parameters: galleryParameters,
  render: () => (
    <>
      {background}
      <CreateKeySlideOver {...editorProps} />
    </>
  ),
};

const waitForRender = (): Promise<void> =>
  new Promise((resolveRender) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolveRender())),
  );

const clickButton = async (text: string): Promise<void> => {
  const button = Array.from(document.querySelectorAll<HTMLButtonElement>(`button`)).find(
    (candidate) => candidate.textContent?.trim() === text,
  );
  if (!button) {
    throw new Error(`Couldn't find ${text} button`);
  }
  button.click();
  await waitForRender();
};

const enterWebsite = async (): Promise<void> => {
  const input = document.querySelector<HTMLInputElement>(`input[type="text"]`);
  const setValue = Object.getOwnPropertyDescriptor(
    HTMLInputElement.prototype,
    `value`,
  )?.set;
  if (!input || !setValue) {
    throw new Error(`Couldn't find website input`);
  }
  setValue.call(input, `school.example.com`);
  input.dispatchEvent(new Event(`input`, { bubbles: true }));
  await waitForRender();
  await clickButton(`Continue`);
};

export const Scope = {
  parameters: galleryParameters,
  render: () => (
    <>
      {background}
      <CreateKeySlideOver {...editorProps} />
    </>
  ),
  play: enterWebsite,
};

export const Review = {
  parameters: galleryParameters,
  render: () => (
    <>
      {background}
      <CreateKeySlideOver {...editorProps} />
    </>
  ),
  play: async () => {
    await enterWebsite();
    await clickButton(`Review key`);
  },
};

export const Edit = {
  parameters: galleryParameters,
  render: () => (
    <>
      {background}
      <EditKeySlideOver {...editProps} keyRecord={existingKey} />
    </>
  ),
};

export const AdvancedTarget = {
  parameters: galleryParameters,
  render: () => (
    <>
      {background}
      <EditKeySlideOver {...editProps} keyRecord={advancedKey} />
    </>
  ),
};
