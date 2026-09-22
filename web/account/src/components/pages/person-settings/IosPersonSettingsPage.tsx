import { Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { MusicDeviceConnection } from './IosSettingsPage.types';
import CardContainer from '#/components/layout/CardContainer';
import MusicSection from '#/components/person-settings/MusicSection';

interface Props {
  personName: string;
  musicConnections: MusicDeviceConnection[];
  defaultExpandedMusic?: boolean;
  children: React.ReactNode;
}

const SectionHeading: React.FC<{ title: string; description: string }> = ({
  title,
  description,
}) => (
  <VStack gap={0.5} className="px-1 @lg/main:px-0">
    <Text as="h2" variant="bodyLargeStrong">
      {title}
    </Text>
    <Text variant="bodyMuted">{description}</Text>
  </VStack>
);

const IosPersonSettingsPage: React.FC<Props> = ({
  personName,
  musicConnections,
  defaultExpandedMusic,
  children,
}) => {
  const showMusic = musicConnections.length > 0;

  return (
    <VStack gap={8} className="pt-1">
      {showMusic && (
        <VStack
          as="section"
          id="music"
          gap={3}
          className="scroll-mt-6 rounded-2xl outline-none target:ring-2 target:ring-violet-300/70 target:ring-offset-4 target:ring-offset-white"
        >
          <SectionHeading
            title="Music"
            description={`Settings apply everywhere ${personName} uses Gertrude Music.`}
          />
          <CardContainer>
            <MusicSection
              connections={musicConnections}
              defaultExpanded={defaultExpandedMusic}
            />
          </CardContainer>
        </VStack>
      )}
      <VStack gap={4}>
        <SectionHeading
          title="Device settings"
          description="Gertrude Blocker and Podcasts settings apply only to the device shown."
        />
        <CardContainer>
          <VStack gap={8}>{children}</VStack>
        </CardContainer>
      </VStack>
    </VStack>
  );
};

export default IosPersonSettingsPage;
