import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
import React from 'react';

interface Props {
  screenshot: string;
  appIcon: string;
  heading: string;
  subheading: string;
  badges: string[];
}

const AppAd: React.FC<Props> = ({ screenshot, appIcon, heading, subheading, badges }) => (
  <Card preset="big" padding={0} className="!rounded-3xl shadow-stone-300/20">
    <HStack justify="center" className="bg-stone-50 h-50 m-3 relative rounded-xl">
      <img
        src={screenshot}
        alt=""
        aria-hidden="true"
        className="w-full h-full object-cover rounded-xl absolute left-0 top-0 scale-100 blur-lg opacity-70"
      />
      <img
        src={screenshot}
        alt={`${heading} screenshot`}
        className="w-full h-full object-cover border border-white rounded-xl relative"
      />
    </HStack>
    <HStack justify="center" className="h-0">
      <img
        src={appIcon}
        alt={`${heading} icon`}
        className="w-20 h-20 rounded-[22px] shadow-md shadow-stone-300/30 -translate-y-4 border border-stone-200"
      />
    </HStack>
    <VStack align="center" className="pt-10 px-8 pb-8">
      <HStack justify="center" gap={2} wrap>
        {badges.map((badge) => (
          <Badge key={badge} color="neutral" size="small">
            {badge}
          </Badge>
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
