import { HStack, Text, Tooltip } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import React from 'react';
import type { ConnectedIOSApp } from '#/components/devices/types';

interface Props {
  apps: ConnectedIOSApp[];
  personId: string;
  deviceId: string;
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

const ConnectedAppList: React.FC<Props> = ({ apps, personId, deviceId }) => {
  if (apps.length === 0) {
    return <Text variant="captionMuted">No Gertrude apps connected</Text>;
  }

  return (
    <HStack wrap gap={2} aria-label="Connected Gertrude apps">
      {apps.map((app) => {
        const details = appDetails[app];
        return (
          <Tooltip key={app} content={`Open ${details.name} settings`} side="top">
            <Link
              to="/people/$personId/ios-settings/$deviceId"
              params={{ personId, deviceId }}
              search={{ section: app }}
              aria-label={`Open ${details.name} settings`}
              className="group relative z-20 rounded-xl outline-none focus-visible:ring-2 focus-visible:ring-violet-300"
            >
              <HStack
                gap={1.5}
                className="rounded-xl border border-stone-200 bg-white p-1.5 pr-2 shadow shadow-stone-300/30 transition-[border-color,box-shadow] group-hover:border-stone-300 group-hover:shadow-stone-300/60"
              >
                <img
                  src={details.iconUrl}
                  alt=""
                  className="h-5 w-5 rounded-[6.5px] object-cover shadow-sm shadow-violet-800/10"
                />
                <Text variant="captionSubtleStrong">{details.shortName}</Text>
              </HStack>
            </Link>
          </Tooltip>
        );
      })}
    </HStack>
  );
};

export default ConnectedAppList;
