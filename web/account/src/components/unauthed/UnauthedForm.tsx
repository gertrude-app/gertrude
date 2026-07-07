import { HStack, Spacer, Text, VStack } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';

interface Props {
  inputs: React.ReactNode[];
  buttons: React.ReactNode[];
  heading: string;
  subheading: string;
  onSubmit?: (event: React.FormEvent) => void;
  bottomLink?: {
    text: string;
    href: string;
  };
  bottomLinkExplanation?: string;
}

const UnauthedForm: React.FC<Props> = ({
  inputs,
  buttons,
  heading,
  subheading,
  onSubmit,
  bottomLink,
  bottomLinkExplanation,
}) => (
  <VStack
    as="form"
    onSubmit={onSubmit}
    className="min-h-screen overflow-hidden bg-stone-50 shadow-stone-500/20 xs:min-h-0 xs:w-96 xs:rounded-2xl xs:border xs:border-stone-200 xs:bg-white xs:shadow-2xl"
  >
    <VStack className="p-6 pt-20 xs:pt-6" gap={1}>
      <Text as="h2" variant="title">
        {heading}
      </Text>
      <Text as="p" variant="bodyMuted" className="max-w-80">
        {subheading}
      </Text>
    </VStack>
    <VStack
      className="xs:bg-stone-100/50 xs:border border-stone-200 p-5 rounded-xl m-1"
      gap={8}
    >
      <VStack className="w-full rounded-2xl" gap={3}>
        {inputs}
      </VStack>
      <VStack gap={3}>{buttons}</VStack>
    </VStack>
    <Spacer hideAbove="xs" />
    {bottomLink && (
      <HStack justify="between" className="pb-4 pt-3 px-6">
        <img src="/logo-icon.svg" alt="" className="w-6 grayscale opacity-20" />
        <VStack align="end">
          <Text variant="captionMuted">{bottomLinkExplanation}</Text>
          <HStack
            as="a"
            gap={0.5}
            className="text-xs text-violet-600 font-medium group"
            href={bottomLink.href}
          >
            <span>{bottomLink.text}</span>
            <ArrowRightIcon
              className="w-3 h-3 group-hover:translate-x-0.5 transition-[translate] duration-150"
              strokeWidth={2.5}
            />
          </HStack>
        </VStack>
      </HStack>
    )}
  </VStack>
);

export default UnauthedForm;
