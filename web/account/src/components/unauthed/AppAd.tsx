import { Card, HStack, Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { LucideIcon } from 'lucide-react';

export type AppAdTag = {
  text: string;
  icon?: LucideIcon;
};

interface Props {
  visual: string;
  heading: string;
  subheading: string;
  tags: AppAdTag[];
}

const AppAd: React.FC<Props> = ({ visual, heading, subheading, tags }) => (
  <Card preset="big" padding={0} className="!rounded-3xl shadow-stone-300/20">
    <div className="relative m-1.5 aspect-[600/410] overflow-hidden rounded-[18px]">
      <img src={visual} alt="" className="h-full w-full object-cover" />
      <div className="pointer-events-none absolute inset-0 rounded-[18px] border border-black/10" />
    </div>
    <VStack align="center" className="px-8 pb-8 pt-3">
      <HStack justify="center" gap={1.5} wrap>
        {tags.map(({ text, icon: Icon }) => (
          <span
            key={text}
            className="inline-flex items-center gap-1 rounded-full bg-stone-100 px-2 py-0.5 text-xs font-medium text-stone-700"
          >
            {Icon && <Icon className="h-3.5 w-3.5 shrink-0" strokeWidth={1.75} />}
            {text}
          </span>
        ))}
      </HStack>
      <Text as="h3" variant="heading" className="text-center mt-2">
        {heading}
      </Text>
      <Text as="h4" variant="body" className="text-center">
        {subheading}
      </Text>
    </VStack>
  </Card>
);

export default AppAd;
