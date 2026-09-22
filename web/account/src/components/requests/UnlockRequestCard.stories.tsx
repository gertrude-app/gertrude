import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { UnlockDomainGroup } from '#/lib/unlockRequests';
import UnlockRequestCard from './UnlockRequestCard';
import { keychains, unlockRequest } from '#/components/storybook/fixtures';
import { buildUnlockReview, updateGroupKeyAddressMatch } from '#/lib/unlockRequests';

const initialGroups: UnlockDomainGroup[] = buildUnlockReview(
  [
    unlockRequest(`docs.example.com`, { requestComment: `For my homework.` }),
    unlockRequest(`docs.example.com`, {
      id: `request-docs-again`,
      requestComment: ` For my homework. `,
    }),
    unlockRequest(`192.0.2.1`, { domain: undefined, ipAddress: `192.0.2.1` }),
    unlockRequest(`school.s3.amazonaws.com`),
    unlockRequest(`classroom.google.com`),
  ],
  keychains[0]!.id,
).flatMap((entry) =>
  entry.kind === `web`
    ? [
        {
          ...updateGroupKeyAddressMatch(
            entry.group,
            [`school.s3.amazonaws.com`, `classroom.google.com`].includes(
              entry.group.target,
            )
              ? `parent`
              : `exact`,
          ),
          decision: `allow` as const,
        },
      ]
    : [],
);

const SettingsAssortment: React.FC = () => {
  const [groups, setGroups] = React.useState(initialGroups);
  return (
    <StoryCanvas>
      {[
        { title: `Exact address and IP settings`, groups: groups.slice(0, 2) },
        { title: `Broad hosting and service warnings`, groups: groups.slice(2) },
      ].map((section) => (
        <StorySection
          key={section.title}
          title={section.title}
          contentClassName="grid grid-cols-1 items-start gap-6 @3xl/main:grid-cols-2"
        >
          {section.groups.map((group) => (
            <UnlockRequestCard
              key={group.id}
              group={group}
              keychainOptions={keychains
                .slice(0, 2)
                .map((keychain) => ({ ...keychain, otherPeople: [] }))}
              defaultSettingsOpen={
                group.target === `docs.example.com` || group.key.type === `ipAddress`
              }
              defaultMatchOptionsOpen={group.target === `docs.example.com`}
              onChange={(updated) =>
                setGroups((current) =>
                  current.map((item) => (item.id === updated.id ? updated : item)),
                )
              }
            />
          ))}
        </StorySection>
      ))}
    </StoryCanvas>
  );
};

export default {
  title: 'Account/Components/Requests/Unlock Request Card',
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export const SettingsAndWarnings = {
  parameters: galleryParameters,
  render: () => <SettingsAssortment />,
};
