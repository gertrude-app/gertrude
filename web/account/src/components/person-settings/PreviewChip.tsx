import { Badge, HStack, Text } from '@gertrude/ui';
import React from 'react';

export type PreviewChipValue = {
  text: string;
  color: `neutral` | `violet`;
};

export type PreviewChipProps = {
  label: string;
  values: PreviewChipValue[];
};

const PreviewChip: React.FC<PreviewChipProps> = ({ label, values }) => (
  <HStack
    gap={{ default: 1.5, '@2xl/main': 2 }}
    className="border border-stone-200 rounded @2xl/main:rounded-lg p-0 @2xl/main:p-0.75 pl-1.25 @2xl/main:pl-2 bg-stone-50 shrink-0"
  >
    <Text variant="caption">{label}</Text>
    <HStack gap={1}>
      {values.map(({ text, color }) => (
        <Badge key={text} size="small" color={color} className="-m-0.25 @2xl/main:m-0">
          {text}
        </Badge>
      ))}
    </HStack>
  </HStack>
);

export default PreviewChip;
