import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { PersonRelationship } from '#/components/types';
import NewPersonPage from './NewPersonPage';

const meta = {
  title: 'Account/Pages/People/New Person',
  component: NewPersonPage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

interface NewPersonPageStoryProps {
  initialRelationship?: PersonRelationship | null;
  initialName?: string;
  creating?: boolean;
  selfRelationshipUnavailable?: boolean;
}

const NewPersonPageStory: React.FC<NewPersonPageStoryProps> = ({
  initialRelationship = null,
  initialName = ``,
  creating,
  selfRelationshipUnavailable,
}) => {
  const [relationship, setRelationship] = React.useState<PersonRelationship | null>(
    initialRelationship,
  );
  const [name, setName] = React.useState(initialName);

  return (
    <NewPersonPage
      relationship={relationship}
      setRelationship={setRelationship}
      name={name}
      setName={setName}
      creating={creating}
      selfRelationshipUnavailable={selfRelationshipUnavailable}
      onFinish={() => {}}
    />
  );
};

const waitForRender = (): Promise<void> =>
  new Promise((resolveRender) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolveRender())),
  );

const advanceToNameStep = async (canvasElement: HTMLElement): Promise<void> => {
  const nextButton = Array.from(
    canvasElement.querySelectorAll<HTMLButtonElement>(`button`),
  ).find((button) => button.textContent?.trim() === `Next`);

  if (!nextButton) {
    throw new Error(`Couldn't find next button`);
  }

  nextButton.click();
  await waitForRender();
};

export const Default = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <NewPersonPageStory />
    </StoryScreen>
  ),
};

export const SelfUnavailable = {
  name: 'Self relationship unavailable',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <StoryScreen>
      <NewPersonPageStory selfRelationshipUnavailable />
    </StoryScreen>
  ),
  play: async ({ canvasElement }: { canvasElement: HTMLElement }) => {
    const selfButton = Array.from(
      canvasElement.querySelectorAll<HTMLButtonElement>(`button`),
    ).find((button) => button.textContent?.trim() === `Yourself`);

    if (!selfButton) {
      throw new Error(`Couldn't find self relationship button`);
    }

    selfButton.focus();
    await new Promise((resolveTooltip) => window.setTimeout(resolveTooltip, 500));
  },
};

export const Self = {
  name: 'Self relationship warning',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <NewPersonPageStory initialRelationship="self" />
    </StoryScreen>
  ),
};

export const Name = {
  name: 'Name step',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <NewPersonPageStory initialRelationship="child" initialName="Jude" />
    </StoryScreen>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) =>
    advanceToNameStep(canvasElement),
};

export const Creating = {
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <StoryScreen>
      <NewPersonPageStory initialRelationship="child" initialName="Jude" creating />
    </StoryScreen>
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) =>
    advanceToNameStep(canvasElement),
};
