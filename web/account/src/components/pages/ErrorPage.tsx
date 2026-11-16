import { Button, HStack, Text, VStack } from '@gertrude/ui';
import { ArrowLeftIcon, RefreshCwIcon, TriangleAlertIcon } from 'lucide-react';
import React from 'react';

interface Props {
  accountHref: string;
  onReload: () => void;
}

const ErrorPage: React.FC<Props> = ({ accountHref, onReload }) => (
  <div className="flex min-h-[70vh] items-center justify-center px-5 py-10">
    <VStack
      align="center"
      justify="center"
      className="w-full max-w-lg rounded-xl border border-stone-200 bg-white bg-dots px-6 py-10 text-center shadow-sm shadow-stone-300/30"
    >
      <TriangleAlertIcon className="h-7 w-7 text-stone-600" />
      <Text as="h1" variant="title" className="mt-3">
        Something went wrong
      </Text>
      <Text as="p" variant="bodyMuted" className="mt-1 mb-5">
        This page ran into an unexpected problem. Reloading usually fixes it.
      </Text>
      <HStack gap={2} justify="center" wrap>
        <Button type="button" onClick={onReload} icon={RefreshCwIcon} variant="primary">
          Reload page
        </Button>
        <Button type="link" href={accountHref} icon={ArrowLeftIcon}>
          Go to People
        </Button>
      </HStack>
      <Text as="p" variant="captionMuted" className="mt-5">
        Still stuck?{` `}
        <a
          href="https://gertrude.app/contact"
          className="font-medium text-violet-700 underline"
        >
          Contact support
        </a>
      </Text>
    </VStack>
  </div>
);

export default ErrorPage;
