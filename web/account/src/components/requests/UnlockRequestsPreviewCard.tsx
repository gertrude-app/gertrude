import { Badge, Card, HStack, Text, VStack, inflect } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { GetAccountUnlockRequestSummary } from '@shared/pairql/src/account';
import RightColumnCard from './RightColumnCard';

interface Props {
  summary: GetAccountUnlockRequestSummary.Output;
  viewAllHref: string;
  reviewHrefForPerson: (personId: string) => string;
}

const UnlockRequestsPreviewCard: React.FC<Props> = ({
  summary,
  viewAllHref,
  reviewHrefForPerson,
}) => {
  if (summary.people.length === 0) {
    return null;
  }

  return (
    <RightColumnCard
      title="Unlock Requests"
      links={[
        {
          text: `View all`,
          href: viewAllHref,
          icon: ArrowRightIcon,
          iconPosition: `right`,
          variant: `ghost`,
        },
      ]}
    >
      <Card padding={3}>
        <VStack>
          {summary.people.slice(0, 3).map((person) => (
            <VStack
              as="a"
              key={person.id}
              href={reviewHrefForPerson(person.id)}
              className="cursor-pointer border-b border-stone-200/80 py-3 first:pt-0 last:border-b-0 last:pb-0"
            >
              <HStack justify="between" gap={2}>
                <Text variant="bodyStrong">{person.name}</Text>
                <Badge color="violet" size="xsmall">
                  {person.pendingCount} {inflect(`request`, person.pendingCount)}
                </Badge>
              </HStack>
              <HStack wrap gap={1} className="mt-0.5">
                {person.targets.slice(0, 3).map((target) => (
                  <Text
                    key={target}
                    variant="captionSubtleStrong"
                    className="max-w-full truncate rounded border border-stone-200 bg-stone-50 px-1"
                  >
                    {target}
                  </Text>
                ))}
                {person.targets.length > 3 && (
                  <Text variant="captionMuted">+ {person.targets.length - 3} more</Text>
                )}
              </HStack>
            </VStack>
          ))}
        </VStack>
      </Card>
    </RightColumnCard>
  );
};

export default UnlockRequestsPreviewCard;
