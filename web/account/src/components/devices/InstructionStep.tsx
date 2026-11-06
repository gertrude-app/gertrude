import { HStack, Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { LucideIcon } from 'lucide-react';

const InstructionStep: React.FC<{
  icon: LucideIcon;
  title: string;
  children: React.ReactNode;
  media?: React.ReactNode;
}> = ({ icon: Icon, title, children, media }) => (
  <div className="rounded-xl border border-stone-200 bg-stone-50/70 p-3.5">
    <HStack align="start" gap={3}>
      <Icon className="mt-1 h-5 w-5 shrink-0 text-stone-600" />
      <VStack gap={1} className="min-w-0">
        <Text variant="bodyStrong">{title}</Text>
        <Text as="div" variant="proseSubtle">
          {children}
        </Text>
        {media}
      </VStack>
    </HStack>
  </div>
);

export default InstructionStep;
