import { Button, Text, VStack } from '@gertrude/ui';
import { ArrowLeftIcon, SquirrelIcon } from 'lucide-react';
import React from 'react';

interface Props {
  accountHref: string;
}

const NotFoundPage: React.FC<Props> = ({ accountHref }) => (
  <main className="flex min-h-screen items-center justify-center bg-stone-50 px-5 py-10">
    <VStack
      align="center"
      justify="center"
      className="w-full max-w-lg rounded-xl border border-stone-200 bg-white bg-dots px-6 py-10 text-center shadow-sm shadow-stone-300/30"
    >
      <SquirrelIcon className="h-7 w-7 text-stone-600" />
      <Text as="h1" variant="title" className="mt-3">
        Page not found
      </Text>
      <Text as="p" variant="bodyMuted" className="mt-1 mb-5">
        The address may be incorrect, or the page may have moved.
      </Text>
      <Button type="link" href={accountHref} icon={ArrowLeftIcon} variant="primary">
        Back to Account
      </Button>
    </VStack>
  </main>
);

export default NotFoundPage;
