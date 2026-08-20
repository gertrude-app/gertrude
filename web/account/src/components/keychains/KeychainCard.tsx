import { Badge, Card, HStack, Text, VStack, inflect } from '@gertrude/ui';
import React from 'react';
import type { Keychain } from '#/components/types';

interface Props extends Pick<Keychain, `name` | `description` | `numKeys` | `isPublic`> {
  details?: React.ReactNode;
  actions?: React.ReactNode;
}

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  description,
  numKeys,
  details,
  actions,
}) => (
  <Card padding={0} className="flex h-full flex-col">
    <Card.Body padding={3} className="flex-grow">
      <VStack gap={0.5}>
        <HStack gap={2}>
          <Text variant="bodyLargeStrong">{name}</Text>
          {isPublic && <Badge size="small">Public</Badge>}
        </HStack>
        {description && <Text variant="captionSubtle">{description}</Text>}
        {details}
      </VStack>
    </Card.Body>
    <Card.Footer className="flex items-center justify-between gap-3">
      <Text variant="captionMuted">
        {numKeys} {inflect(`key`, numKeys)}
      </Text>
      {actions}
    </Card.Footer>
  </Card>
);

export default KeychainCard;
