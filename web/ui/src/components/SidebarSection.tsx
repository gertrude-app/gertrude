import React from 'react';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';

interface Props {
  title?: string;
  children: React.ReactNode;
}

const SidebarSection: React.FC<Props> = ({ title, children }) => (
  <VStack gap={2}>
    <Text variant="label" className="select-none">
      {title}
    </Text>
    <VStack>{children}</VStack>
  </VStack>
);

export default SidebarSection;
