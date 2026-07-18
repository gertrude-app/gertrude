import { HStack, VStack } from '@gertrude/ui';
import React from 'react';

interface Props {
  heading: React.ReactNode;
  children: React.ReactNode;
}

const DashboardPage: React.FC<Props> = ({ heading, children }) => (
  <HStack justify="center" align="stretch">
    <div className="py-2 min-[940px]:py-16 flex-grow max-w-[1200px] @container/main">
      <VStack
        gap={{ default: 4, '@2xl/main': 8 }}
        className="px-3 @lg/main:px-4 @xl/main:px-8 @3xl/main:px-12"
      >
        {heading}
        {children}
      </VStack>
    </div>
  </HStack>
);

export default DashboardPage;
