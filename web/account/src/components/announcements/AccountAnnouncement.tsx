import { Banner, Button } from '@gertrude/ui';
import React from 'react';
import AnnouncementBanner from './AnnouncementBanner';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useOptimism, useQuery } from '#/pairql/query';

const AccountAnnouncement: React.FC = () => {
  const optimism = useOptimism();
  const query = useQuery(Key.announcement, () => liveClient.getAccountAnnouncement(), {
    refetchInterval: 60_000,
  });
  const dismiss = useMutation(
    (id: string) => liveClient.dismissAccountAnnouncement({ id }),
    {
      onSuccess: () => {
        optimism.update(Key.announcement, {});
      },
      invalidating: [Key.announcement],
    },
  );
  const announcement = query.data?.announcement;

  if (announcement) {
    return (
      <AnnouncementBanner
        key={announcement.id}
        announcement={announcement}
        onDismiss={() => dismiss.mutate(announcement.id)}
        dismissing={dismiss.isPending && dismiss.variables === announcement.id}
        error={
          dismiss.isError && dismiss.variables === announcement.id
            ? (dismiss.error.userMessage ??
              `Couldn't dismiss this announcement. Please try again.`)
            : undefined
        }
      />
    );
  }

  if (query.isError) {
    return (
      <Banner showIcon={false}>
        <div role="alert" className="flex flex-wrap items-center gap-x-3 gap-y-2">
          <span>Couldn't load announcements.</span>
          <Button
            type="button"
            size="small"
            onClick={() => void query.refetch()}
            loading={query.isFetching}
          >
            Try again
          </Button>
        </div>
      </Banner>
    );
  }

  return null;
};

export default AccountAnnouncement;
