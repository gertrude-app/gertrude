import { Button, HStack, Text } from '@gertrude/ui';
import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import KeychainCard from './KeychainCard';
import { keychains } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Components/Keychains/Keychain Card',
  component: KeychainCard,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const Assortment = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="Summary cards"
        contentClassName="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2"
      >
        <KeychainCard
          name={keychains[0]!.name}
          nameHref={`/keychains/${keychains[0]!.id}`}
          description={keychains[0]!.description}
          numKeys={keychains[0]!.numKeys}
          isPublic={keychains[0]!.isPublic}
          actions={
            <HStack gap={1} align="center">
              <Text variant="label">Assigned to</Text>
              <Button type="button" size="small" variant="default" onClick={() => {}}>
                2 people
              </Button>
            </HStack>
          }
        />
        <KeychainCard
          name={keychains[2]!.name}
          nameHref={`/keychains/${keychains[2]!.id}`}
          description={keychains[2]!.description}
          numKeys={keychains[2]!.numKeys}
          isPublic={keychains[2]!.isPublic}
          details={
            <Text variant="captionStrong" className="mt-1">
              Weekdays, 8:00 AM–4:00 PM
            </Text>
          }
        />
      </StorySection>
    </StoryCanvas>
  ),
};
