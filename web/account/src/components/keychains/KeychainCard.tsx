import { Badge, Button, Card, HStack, Text, VStack, inflect } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { Keychain } from '#/components/types';

interface Props extends Pick<Keychain, `name` | `description` | `numKeys` | `isPublic`> {
  nameHref?: string;
  details?: React.ReactNode;
  actions?: React.ReactNode;
}

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  description,
  numKeys,
  nameHref,
  details,
  actions,
}) => (
  <Card padding={0} className="flex h-full flex-col">
    <Card.Body padding={3} className="flex-grow">
      <VStack gap={0.5}>
        <HStack gap={2}>
          {nameHref ? (
            <Text
              as={Link}
              to={nameHref}
              variant="bodyLargeStrong"
              className="rounded-sm outline-none transition-colors hover:text-violet-700 focus-visible:ring-2 focus-visible:ring-violet-300/80"
            >
              {name}
            </Text>
          ) : (
            <Text variant="bodyLargeStrong">{name}</Text>
          )}
          {isPublic && <Badge size="small">Public</Badge>}
        </HStack>
        {description && <Text variant="captionSubtle">{description}</Text>}
        {details}
      </VStack>
    </Card.Body>
    <Card.Footer className="flex flex-wrap items-center justify-between gap-3">
      <Text variant="captionMuted">
        {numKeys} {inflect(`key`, numKeys)}
      </Text>
      {(actions || nameHref) && (
        <HStack gap={2} align="center" className="ml-auto flex-wrap justify-end">
          {actions}
          {nameHref && (
            <Button
              type="link"
              href={nameHref}
              variant="default"
              size="small"
              icon={ArrowRightIcon}
              iconPosition="right"
            >
              View keys
            </Button>
          )}
        </HStack>
      )}
    </Card.Footer>
  </Card>
);

export default KeychainCard;
