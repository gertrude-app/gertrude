import { Button, HStack, Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { ButtonLink } from '#/components/types';

interface Props {
  children: React.ReactNode;
  title: string;
  links?: ButtonLink[];
}

const RightColumnCard: React.FC<Props> = ({ children, title, links }) => (
  <VStack gap={1} className="bg-stone-50 border border-stone-200 rounded-2xl p-1.25">
    <Text variant="captionSubtleStrong" className="ml-3">
      {title}
    </Text>
    {children}
    {links && (
      <HStack justify="end">
        {links.map((link) => (
          <Button
            key={`${link.href}-${link.text}`}
            type="link"
            href={link.href}
            variant={link.variant}
            icon={link.icon}
            iconPosition={link.iconPosition}
            size="small"
          >
            {link.text}
          </Button>
        ))}
      </HStack>
    )}
  </VStack>
);

export default RightColumnCard;
