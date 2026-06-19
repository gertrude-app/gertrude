import { Banner, Button, EmptyState, Input, SlideOver } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import { MusicIcon, PlusIcon } from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/CardContainer';
import AllowedAlbumCard from '#/components/person-settings/AllowedAlbumCard';
import BlockGroup from '#/components/person-settings/BlockGroup';
import PersonSettingsExpandableSection from '#/components/person-settings/PersonSettingsExpandableSection';
import SettingsRow from '#/components/person-settings/SettingsRow';
import {
  type PersonIosSettingsConfiguration,
  getPersonIosSettingsPage,
  useMockData,
} from '#/lib/mock';

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

type AllowedAlbum = PersonIosSettingsConfiguration[`allowedAlbums`][number];

const albumSearchCatalog: AllowedAlbum[] = [
  {
    title: `Abbey Road`,
    artist: `The Beatles`,
    artworkUrl: `https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/df/db/61/dfdb615d-47f8-06e9-9533-b96daccc029f/18UMGIM31076.rgb.jpg/300x300bb.jpg`,
    showAlbumArt: true,
  },
  {
    title: `The Muppet Movie`,
    artist: `Kermit the Frog`,
    artworkUrl: `https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/0f/d8/15/0fd815cb-45f4-b334-e26d-0ea9875795e3/00050087348533.rgb.jpg/300x300bb.jpg`,
    showAlbumArt: true,
  },
  {
    title: `Bluey: The Album`,
    artist: `Bluey`,
    artworkUrl: `https://picsum.photos/seed/bluey-album/300/300`,
    showAlbumArt: true,
  },
  {
    title: `The Planets`,
    artist: `Gustav Holst`,
    artworkUrl: `https://picsum.photos/seed/the-planets/300/300`,
    showAlbumArt: false,
  },
  {
    title: `Minecraft Volume Alpha`,
    artist: `C418`,
    artworkUrl: `https://picsum.photos/seed/minecraft-volume-alpha/300/300`,
    showAlbumArt: true,
  },
  {
    title: `Encanto`,
    artist: `Lin-Manuel Miranda`,
    artworkUrl: `https://picsum.photos/seed/encanto-album/300/300`,
    showAlbumArt: true,
  },
  {
    title: `A Charlie Brown Christmas`,
    artist: `Vince Guaraldi Trio`,
    artworkUrl: `https://picsum.photos/seed/charlie-brown-christmas/300/300`,
    showAlbumArt: true,
  },
];

const albumKey = (album: AllowedAlbum): string => `${album.title}::${album.artist}`;

const albumMatchesSearchQuery = (album: AllowedAlbum, query: string): boolean => {
  const normalizedQuery = query.trim().toLowerCase();

  if (!normalizedQuery) {
    return true;
  }

  return `${album.title} ${album.artist}`.toLowerCase().includes(normalizedQuery);
};

const IosSettingsPage: React.FC = () => {
  const { personId } = Route.useParams();
  const [addAlbumSlideOverOpen, setAddAlbumSlideOverOpen] = React.useState(false);
  const [albumSearchQuery, setAlbumSearchQuery] = React.useState(``);
  const [selectedAlbumKeys, setSelectedAlbumKeys] = React.useState<string[]>([]);
  const { db, dispatch } = useMockData();
  const { config, iosDevices } = getPersonIosSettingsPage(db, personId);
  const patchConfig = (patch: Partial<PersonIosSettingsConfiguration>): void => {
    dispatch({ type: `iosSettings.patch`, personId, patch });
  };

  if (!config || iosDevices.length === 0) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <span className="text-center text-sm text-stone-500">
          No iPhone/iPad settings to configure.
        </span>
      </CardContainer>
    );
  }

  const blockedGroupCount = Object.values(config.blockedGroups).filter(Boolean).length;
  const allowedAlbumKeys = config.allowedAlbums.map(albumKey);
  const filteredAlbumCatalog = albumSearchCatalog.filter((album) =>
    albumMatchesSearchQuery(album, albumSearchQuery),
  );
  const selectedAlbums = albumSearchCatalog.filter((album) =>
    selectedAlbumKeys.includes(albumKey(album)),
  );
  const openAddAlbumSlideOver = (): void => {
    setSelectedAlbumKeys([]);
    setAlbumSearchQuery(``);
    setAddAlbumSlideOverOpen(true);
  };
  const closeAddAlbumSlideOver = (): void => {
    setSelectedAlbumKeys([]);
    setAlbumSearchQuery(``);
    setAddAlbumSlideOverOpen(false);
  };
  const toggleSelectedAlbum = (album: AllowedAlbum): void => {
    const key = albumKey(album);

    if (allowedAlbumKeys.includes(key)) {
      return;
    }

    setSelectedAlbumKeys((currentKeys) =>
      currentKeys.includes(key)
        ? currentKeys.filter((currentKey) => currentKey !== key)
        : [...currentKeys, key],
    );
  };
  const addSelectedAlbums = (): void => {
    const albumsToAdd = selectedAlbums.filter(
      (album) => !allowedAlbumKeys.includes(albumKey(album)),
    );

    if (albumsToAdd.length === 0) {
      return;
    }

    patchConfig({ allowedAlbums: [...config.allowedAlbums, ...albumsToAdd] });
    closeAddAlbumSlideOver();
  };

  return (
    <>
      <CardContainer className="flex flex-col gap-4">
        <PersonSettingsExpandableSection
          appIconUrl="/gertrude-app-icons/blocker.webp"
          title="Gertrude Blocker"
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
            <div className="bg-white border border-stone-200 rounded-xl shadow shadow-stone-300/30 flex flex-col overflow-hidden">
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
            </div>
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
          <div className="flex flex-col gap-3 mt-3">
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
          </div>
        </PersonSettingsExpandableSection>
        <PersonSettingsExpandableSection
          appIconUrl="/gertrude-app-icons/music.png"
          title="Gertrude Music"
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
              <div className="flex flex-col gap-3">
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
                <div className="flex justify-end">
                  <Button type="button" onClick={openAddAlbumSlideOver} icon={PlusIcon}>
                    Add Album
                  </Button>
                </div>
              </div>
            ) : (
              <EmptyState
                icon={MusicIcon}
                title="No Allowed Albums"
                description="Add albums that can be played in Gertrude Music."
                button={{
                  text: `Add Album`,
                  type: `button`,
                  onClick: openAddAlbumSlideOver,
                  icon: PlusIcon,
                  variant: `primary`,
                }}
              />
            )}
          </SettingsRow>
        </PersonSettingsExpandableSection>
        <PersonSettingsExpandableSection
          appIconUrl="/gertrude-app-icons/am.webp"
          title="Gertrude Podcasts"
          previewChips={[]}
        >
          hi
        </PersonSettingsExpandableSection>
      </CardContainer>
      <SlideOver
        open={addAlbumSlideOverOpen}
        onOpenChange={(open) => {
          if (!open) {
            closeAddAlbumSlideOver();
          }
        }}
        ariaLabel="Add allowed albums"
        heading="Add allowed albums"
        subheading="Search for albums to allow in Gertrude Music."
        size="large"
      >
        <div className="flex h-full flex-col">
          <div className="shrink-0 px-3 pb-4 @lg/slide:px-6">
            <Input
              type="text"
              value={albumSearchQuery}
              setValue={setAlbumSearchQuery}
              placeholder="Search albums or artists..."
            />
          </div>
          <div className="min-h-0 flex-1 overflow-y-auto px-3 pb-4 @lg/slide:px-6">
            {filteredAlbumCatalog.length > 0 ? (
              <div className="grid grid-cols-2 gap-4 @md/slide:grid-cols-3">
                {filteredAlbumCatalog.map((album) => {
                  const key = albumKey(album);
                  const selected = selectedAlbumKeys.includes(key);
                  const alreadyAllowed = allowedAlbumKeys.includes(key);

                  return (
                    <AllowedAlbumCard
                      key={key}
                      album={album}
                      forceShowArtwork
                      selected={selected}
                      disabled={alreadyAllowed}
                      disabledLabel={alreadyAllowed ? `Already added` : undefined}
                      onSelect={() => toggleSelectedAlbum(album)}
                    />
                  );
                })}
              </div>
            ) : (
              <EmptyState
                icon={MusicIcon}
                title="No Albums Found"
                description="Try a different album title or artist."
              />
            )}
          </div>
          <div className="flex shrink-0 items-center justify-between gap-3 border-t border-stone-200 bg-stone-50/95 px-3 py-3 @lg/slide:px-6 @lg/slide:py-4">
            <span className="text-sm text-stone-600">
              {selectedAlbums.length === 0
                ? `Select one or more albums`
                : `${selectedAlbums.length} album${
                    selectedAlbums.length === 1 ? `` : `s`
                  } selected`}
            </span>
            <Button
              type="button"
              variant="primary"
              disabled={selectedAlbums.length === 0}
              onClick={addSelectedAlbums}
            >
              {selectedAlbums.length === 0
                ? `Add Album`
                : `Add ${selectedAlbums.length} Album${
                    selectedAlbums.length === 1 ? `` : `s`
                  }`}
            </Button>
          </div>
        </div>
      </SlideOver>
    </>
  );
};

export const Route = createFileRoute(`/_app/people/$personId/ios-settings`)({
  component: IosSettingsPage,
});
