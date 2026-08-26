import { HStack, Text, Tooltip } from '@gertrude/ui';
import React from 'react';
import type { ConnectedIOSApp } from '#/components/devices/types';

interface Props {
  apps: ConnectedIOSApp[];
}

const appDetails: Record<
  ConnectedIOSApp,
  { name: string; shortName: string; iconUrl: string }
> = {
  blocker: {
    name: `Gertrude Blocker`,
    shortName: `Blocker`,
    iconUrl: `/gertrude-app-icons/blocker.webp`,
  },
  podcasts: {
    name: `Gertrude Podcasts`,
    shortName: `Podcasts`,
    iconUrl: `/gertrude-app-icons/podcasts.webp`,
  },
  music: {
    name: `Gertrude Music`,
    shortName: `Music`,
    iconUrl: `/gertrude-app-icons/music.webp`,
  },
};

const ConnectedAppList: React.FC<Props> = ({ apps }) => {
  if (apps.length === 0) {
    return <Text variant="captionMuted">No Gertrude apps connected</Text>;
  }

  return (
    <HStack wrap gap={2} aria-label="Connected Gertrude apps">
      {apps.map((app) => {
        const details = appDetails[app];
        return (
          <Tooltip key={app} content={details.name} side="top">
            <HStack
              gap={1.5}
              aria-label={`${details.name} connected`}
              className="bg-white p-1.5 pr-2 border border-stone-200 shadow shadow-stone-300/30 rounded-xl"
            >
              <img
                src={details.iconUrl}
                alt=""
                className="h-5 w-5 rounded-[6.5px] object-cover shadow-sm shadow-violet-800/10"
              />
              <Text variant="captionSubtleStrong">{details.shortName}</Text>
            </HStack>
          </Tooltip>
        );
      })}
    </HStack>
  );
};

export default ConnectedAppList;
