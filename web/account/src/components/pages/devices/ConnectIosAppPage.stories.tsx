import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import ConnectIosAppPage from './ConnectIosAppPage';

type Props = ComponentProps<typeof ConnectIosAppPage>;

const noop = (): void => {};
const people: Props[`people`] = [
  { id: `person-jude`, name: `Jude` },
  { id: `person-mabel`, name: `Mabel` },
];

const defaultProps: Props = {
  flow: `podcasts`,
  device: { type: `iPhone`, modelName: `iPhone 15 Pro`, modelIdentifier: `iPhone16,1` },
  people,
  onSubmit: noop,
  onCancel: noop,
};

const renderPage = (props: Partial<Props> = {}): ReactElement => (
  <StoryScreen>
    <ConnectIosAppPage {...defaultProps} {...props} />
  </StoryScreen>
);

const meta = {
  title: 'Account/Pages/Connect iOS App',
  component: ConnectIosAppPage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const ChoosePerson = {
  name: 'Choose a person',
  parameters: galleryParameters,
  render: () => renderPage(),
};

export const ExistingPersonSelected = {
  name: 'Existing person selected',
  parameters: galleryParameters,
  render: () => renderPage({ initialSelection: { type: `existing`, id: `person-jude` } }),
};

export const AddSomeoneNew = {
  name: 'Add someone new',
  parameters: galleryParameters,
  render: () => renderPage({ initialSelection: { type: `new`, name: `` } }),
};

export const NoPeopleYet = {
  name: 'No people yet',
  parameters: galleryParameters,
  render: () => renderPage({ people: [] }),
};

export const NewPeer = {
  name: 'New peer',
  parameters: galleryParameters,
  render: () =>
    renderPage({ initialSelection: { type: `new`, name: `Mika`, relationship: `peer` } }),
};

export const SelfManaged = {
  name: 'Yourself',
  parameters: galleryParameters,
  render: () =>
    renderPage({ initialSelection: { type: `new`, name: `Mika`, relationship: `self` } }),
};

export const SelfUnavailable = {
  name: 'Yourself unavailable',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      initialSelection: { type: `new`, name: `Mika` },
      selfRelationshipUnavailable: true,
    }),
};

export const Connecting = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      initialSelection: { type: `existing`, id: `person-mabel` },
      submitting: true,
    }),
};

export const ClaimFailed = {
  name: 'Claim failed',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      initialSelection: { type: `existing`, id: `person-jude` },
      error: `Couldn't connect this device. Check your connection and try again.`,
    }),
};

export const MusicOnIpad = {
  name: 'Music on iPad',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      flow: `music`,
      device: {
        type: `iPad`,
        modelName: `iPad Air (5th generation)`,
        modelIdentifier: `iPad13,16`,
      },
      initialSelection: { type: `existing`, id: `person-mabel` },
    }),
};

export const BlockerConnection = {
  name: 'Blocker connection',
  parameters: galleryParameters,
  render: () => renderPage({ flow: `blockerConnect` }),
};

export const BlockerSupervision = {
  name: 'Blocker supervision',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      flow: `blockerSupervise`,
      initialSelection: { type: `existing`, id: `person-jude` },
    }),
};
