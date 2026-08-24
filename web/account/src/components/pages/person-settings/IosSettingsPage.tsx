import { Banner, Button, Card, EmptyState, HStack, Text, VStack } from '@gertrude/ui';
import { MusicIcon, PlusIcon } from 'lucide-react';
import React from 'react';
import type { AllowedAlbum, PersonIosSettingsConfiguration } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import AddAllowedAlbumsSlideOver from '#/components/person-settings/AddAllowedAlbumsSlideOver';
import AllowedAlbumCard from '#/components/person-settings/AllowedAlbumCard';
import BlockGroup from '#/components/person-settings/BlockGroup';
import PersonSettingsExpandableSection from '#/components/person-settings/PersonSettingsExpandableSection';
import SettingsRow from '#/components/person-settings/SettingsRow';
import { albumKey } from '#/components/utils';

type IosSettingsSection = `blocker` | `music` | `podcasts`;

interface Props {
  config?: PersonIosSettingsConfiguration;
  hasIosDevices: boolean;
  albumCatalog: AllowedAlbum[];
  defaultExpandedSections?: IosSettingsSection[];
  patchConfig: (patch: Partial<PersonIosSettingsConfiguration>) => void;
}

const emptyDefaultExpandedSections: IosSettingsSection[] = [];

const iosBlockGroups = [
  {
    id: `appleMusic`,
    title: `Apple Music`,
    shortDescription: `Block artwork and video content in the Apple Music app.`,
    longExplanation: `Blocks album artwork, artist photos, music videos, and Apple TV content in the Apple Music app. Album art and music videos can contain explicit or inappropriate imagery. Enabling this group will show grey placeholder squares in place of artwork, and prevent music videos and Apple TV from playing.`,
  },
  {
    id: `whatsApp`,
    title: `WhatsApp`,
    shortDescription: `Partial WhatsApp blocking. WARNING: likely breaks voice/video calls.`,
    longExplanation: `Aggressive WhatsApp blocking, including channel media, in-app browsing, Meta AI traffic, and most non-WhatsApp traffic the app touches. WARNING: likely breaks voice and video calls, and may cause other in-app features to stop working. Makes the app safer, but not fully safe.`,
  },
  {
    id: `musicRecognition`,
    title: `Music Recognition`,
    shortDescription: `Block iOS music recognition (Shazam, Control Center identify song, etc.) and the album artwork it displays.`,
    longExplanation: `Blocks Apple's built-in music recognition daemon, which powers the Control Center "identify song" button, the Shazam app, and other system surfaces. Also suppresses album artwork shown in the Music Recognition results UI. Enabling this group will prevent songs from being identified at all, and any artwork that would appear will be replaced with a grey placeholder.`,
  },
  {
    id: `gifs`,
    title: `GIFs`,
    shortDescription: `Block GIFs in Messages #images, WhatsApp, Signal, and more.`,
    longExplanation: `Blocks viewing and searching for GIFs in the #images feature of Apple's texting app, plus in other common messaging apps like WhatsApp, Skype, and Signal.`,
  },
  {
    id: `appleMapsImages`,
    title: `Apple Maps Images`,
    shortDescription: `Block all images from Apple Maps business listings.`,
    longExplanation: `Apple Maps business listings show photos uploaded by customers and businesses, and for certain types of businesses, these can be explicit. This group blocks all images from within Apple Maps.`,
  },
  {
    id: `aiFeatures`,
    title: `AI Features`,
    shortDescription: `Block certain cloud-based AI features like image recognition.`,
    longExplanation: `Blocks certain cloud-based AI features like image recognition. For example, the iOS 18 feature where an item in a photo can be long-pressed, identified, and searched for online.`,
  },
  {
    id: `appStoreImages`,
    title: `App Store Images`,
    shortDescription: `Block images from the App Store.`,
    longExplanation: `Eliminates all images for apps in the App Store, and in other places where the App Store appears, like in the Messages texting app.`,
  },
  {
    id: `spotlight`,
    title: `Spotlight`,
    shortDescription: `Block internet searches through Spotlight.`,
    longExplanation: `The built in search bar in iOS (called Spotlight) allows searching for information and images from the internet. This group stops all spotlight internet searches. On-device data searches are not blocked.`,
  },
  {
    id: `ads`,
    title: `Ads`,
    shortDescription: `Block the most common ad providers across all apps.`,
    longExplanation: `Blocks the 20 most common ad providers, including Google ads, in all browsers and apps. Does not guarantee to block all ads, but should make a noticeable difference.`,
  },
  {
    id: `appleDotCom`,
    title: `apple.com`,
    shortDescription: `Block web access to apple.com and linked sites.`,
    longExplanation: `Certain parts of iOS (including the Settings app) contain links to the apple.com website. It is possible to view these pages and from there follow links to other parts of the web. This group blocks this access.`,
  },
  {
    id: `spotifyImages`,
    title: `Spotify Images`,
    shortDescription: `Block images from the Spotify app.`,
    longExplanation: `Blocks images displayed in the Spotify app, including album artwork, artist photos, and playlist covers. This helps prevent exposure to potentially explicit or inappropriate imagery while still allowing music playback.`,
  },
] as const;

const IosSettingsPage: React.FC<Props> = ({
  config,
  hasIosDevices,
  albumCatalog,
  defaultExpandedSections = emptyDefaultExpandedSections,
  patchConfig,
}) => {
  const [addAlbumSlideOverOpen, setAddAlbumSlideOverOpen] = React.useState(false);

  if (!config || !hasIosDevices) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <Text variant="bodyMuted" className="text-center">
          No iPhone/iPad settings to configure.
        </Text>
      </CardContainer>
    );
  }

  const blockedGroupCount = Object.values(config.blockedGroups).filter(Boolean).length;

  return (
    <>
      <CardContainer className="flex flex-col gap-4">
        <PersonSettingsExpandableSection
          appIconUrl="/gertrude-app-icons/blocker.webp"
          title="Gertrude Blocker"
          defaultExpanded={defaultExpandedSections.includes(`blocker`)}
          previewChips={[
            {
              title: `Blocked Groups`,
              values: [
                {
                  text: `${blockedGroupCount} groups`,
                  color: blockedGroupCount > 0 ? `violet` : `neutral`,
                },
              ],
            },
          ]}
        >
          <SettingsRow
            type="alwaysOn"
            title="Blocked Groups"
            description="These content categories are blocked on iPhones and iPads."
          >
            <Card padding={0} className="overflow-hidden">
              {iosBlockGroups.map((group) => (
                <BlockGroup
                  key={group.id}
                  title={group.title}
                  shortDescription={group.shortDescription}
                  longExplanation={group.longExplanation}
                  blocked={config.blockedGroups[group.id]}
                  setBlocked={(blocked) =>
                    patchConfig({
                      blockedGroups: {
                        ...config.blockedGroups,
                        [group.id]: blocked,
                      },
                    })
                  }
                />
              ))}
            </Card>
          </SettingsRow>
          <div className="flex items-center gap-3 mt-8 mb-4">
            <div className="h-[1.5px] flex-grow bg-stone-200 rounded-full" />
            <span className="font-medium text-stone-900">
              Supervision Profile Settings
            </span>
            <div className="h-[1.5px] flex-grow bg-stone-200 rounded-full" />
          </div>
          <Banner variant="neutral">
            After changing any setting below, you’ll need to sync the profile on the
            iPhone by opening the Gertrude app and going to{` `}
            <strong>Info → Sync Profile</strong>.
          </Banner>
          <VStack gap={3} className="mt-3">
            <SettingsRow
              title="Prevent Protection Removal"
              description="Make it impossible for the iPhone user to remove Gertrude’s protection."
              type="toggle"
              enabled={config.preventProtectionRemoval}
              setEnabled={(enabled) => patchConfig({ preventProtectionRemoval: enabled })}
              warning="The iPhone user may remove the profile in order to stop Gertrude’s protection and uninstall."
              showWarning={!config.preventProtectionRemoval}
            />
            <SettingsRow
              title="Allow Deleting Apps"
              description="Keeping this off prevents the iPhone user from deleting the Gertrude app, but also prevents them from deleting any app. Enable temporarily if you need to delete some apps from the iPhone, then re-enable."
              type="toggle"
              enabled={config.allowDeletingApps}
              setEnabled={(enabled) => patchConfig({ allowDeletingApps: enabled })}
              warning="The user can delete apps (including Gertrude Blocker) from their iPhone."
              showWarning={config.allowDeletingApps}
            />
            <SettingsRow
              title="Allow Factory Reset"
              description="Allow the iPhone to be erased and reset to factory settings, bypassing protection."
              type="toggle"
              enabled={config.allowFactoryReset}
              setEnabled={(enabled) => patchConfig({ allowFactoryReset: enabled })}
              warning="The user will be able to erase the iPhone, removing Gertrude and all restrictions."
              showWarning={config.allowFactoryReset}
            />
            <SettingsRow
              title="Allow Installing Apps"
              description="Allow the iPhone user to install new apps from the App Store. Turn this off to remove the App Store icon entirely and block app installation."
              type="toggle"
              enabled={config.allowInstallingApps}
              setEnabled={(enabled) => patchConfig({ allowInstallingApps: enabled })}
            />
          </VStack>
        </PersonSettingsExpandableSection>
        <PersonSettingsExpandableSection
          appIconUrl="/gertrude-app-icons/music.png"
          title="Gertrude Music"
          defaultExpanded={defaultExpandedSections.includes(`music`)}
          previewChips={[
            {
              title: `Allowed Albums`,
              values: [
                {
                  text: `${config.allowedAlbums.length}`,
                  color: config.allowedAlbums.length > 0 ? `violet` : `neutral`,
                },
              ],
            },
          ]}
        >
          <SettingsRow
            title="Allowed Albums"
            description="Albums that will be allowed to be played on the Gertrude Music app on the user's iPhone."
            type="alwaysOn"
          >
            {config.allowedAlbums.length > 0 ? (
              <VStack gap={3}>
                <div className="grid grid-cols-1 @lg/main:grid-cols-2 @3xl/main:grid-cols-3 @5xl/main:grid-cols-4 gap-4">
                  {config.allowedAlbums.map((album) => (
                    <AllowedAlbumCard
                      key={albumKey(album)}
                      album={album}
                      onToggleAlbumArt={() =>
                        patchConfig({
                          allowedAlbums: config.allowedAlbums.map((allowedAlbum) =>
                            albumKey(allowedAlbum) === albumKey(album)
                              ? {
                                  ...allowedAlbum,
                                  showAlbumArt: !allowedAlbum.showAlbumArt,
                                }
                              : allowedAlbum,
                          ),
                        })
                      }
                      onRemove={() =>
                        patchConfig({
                          allowedAlbums: config.allowedAlbums.filter(
                            (allowedAlbum) => albumKey(allowedAlbum) !== albumKey(album),
                          ),
                        })
                      }
                    />
                  ))}
                </div>
                <HStack justify="end">
                  <Button
                    type="button"
                    onClick={() => setAddAlbumSlideOverOpen(true)}
                    icon={PlusIcon}
                  >
                    Add Album
                  </Button>
                </HStack>
              </VStack>
            ) : (
              <EmptyState
                icon={MusicIcon}
                title="No Allowed Albums"
                description="Add albums that can be played in Gertrude Music."
                button={{
                  text: `Add Album`,
                  type: `button`,
                  onClick: () => setAddAlbumSlideOverOpen(true),
                  icon: PlusIcon,
                  variant: `primary`,
                }}
              />
            )}
          </SettingsRow>
        </PersonSettingsExpandableSection>
        <PersonSettingsExpandableSection
          appIconUrl="/gertrude-app-icons/podcasts.webp"
          title="Gertrude Podcasts"
          defaultExpanded={defaultExpandedSections.includes(`podcasts`)}
          previewChips={[]}
        >
          hi
        </PersonSettingsExpandableSection>
      </CardContainer>
      <AddAllowedAlbumsSlideOver
        open={addAlbumSlideOverOpen}
        onOpenChange={setAddAlbumSlideOverOpen}
        catalog={albumCatalog}
        allowedAlbums={config.allowedAlbums}
        onAdd={(albums) =>
          patchConfig({ allowedAlbums: [...config.allowedAlbums, ...albums] })
        }
      />
    </>
  );
};

export default IosSettingsPage;
