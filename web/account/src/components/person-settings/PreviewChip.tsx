import { Badge } from '@gertrude/ui';
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
  <div className="border border-stone-200 rounded @2xl/main:rounded-lg p-0 @2xl/main:p-0.75 pl-1.25 @2xl/main:pl-2 flex items-center gap-1.5 @2xl/main:gap-2 bg-stone-50 shrink-0">
    <span className="text-xs text-stone-700">{label}</span>
    <div className="flex gap-1 @2xl/main:gap-1">
      {values.map(({ text, color }) => (
        <Badge key={text} size="small" color={color} className="-m-0.25 @2xl/main:m-0">
          {text}
        </Badge>
      ))}
    </div>
  </div>
);

export default PreviewChip;
