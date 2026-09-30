import { toast } from '@gertrude/ui';
import React from 'react';
import type { PqlError } from '@shared/pairql';
import type AccountClient from '@shared/pairql/account';
import type {
  ApproveMusicArtist_v2,
  GetMusicAlbumCuration,
  GetMusicCuration,
  RemoveApprovedMusicArtist,
  SaveMusicAlbumCuration,
  SearchMusicCatalog_v2,
} from '@shared/pairql/src/account';
import type { UseMutationResult, UseQueryResult } from '@tanstack/react-query';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useOptimism, useQuery } from '#/pairql/query';

type SearchItem = SearchMusicCatalog_v2.Output[`items`][number];
type SearchTrack = NonNullable<SearchItem[`track`]>;
type SearchAlbum = NonNullable<SearchItem[`album`]>;
type SearchArtist = NonNullable<SearchItem[`artist`]>;
type ArtistConfirmation = NonNullable<ApproveMusicArtist_v2.Output[`confirmation`]>;
type ApprovedArtist = GetMusicCuration.Output[`artists`][number];
type ApprovedAlbum = GetMusicCuration.Output[`albums`][number];
type AlbumRemoval = { album: ApprovedAlbum; revision: number };
type ExpandedAlbum = {
  id: string;
  surface: `library` | `search`;
  rowId: string;
  session: number;
};

export type MusicCurationClient = Pick<
  AccountClient,
  | `getMusicCuration`
  | `getMusicAlbumCuration`
  | `searchMusicCatalog`
  | `approveMusicTrack`
  | `approveMusicAlbum`
  | `approveMusicArtist`
  | `removeApprovedMusicArtist`
  | `saveMusicAlbumCuration`
>;

export interface MusicCurationState {
  query: string;
  setQuery: React.Dispatch<React.SetStateAction<string>>;
  searchOpen: boolean;
  setSearchOpen: React.Dispatch<React.SetStateAction<boolean>>;
  expandedAlbum: ExpandedAlbum | undefined;
  albumMessage: string | undefined;
  artistConfirmation:
    { artist: SearchArtist; confirmation: ArtistConfirmation } | undefined;
  setArtistConfirmation: React.Dispatch<
    React.SetStateAction<MusicCurationState[`artistConfirmation`]>
  >;
  artistToRemove: ApprovedArtist | undefined;
  setArtistToRemove: React.Dispatch<React.SetStateAction<ApprovedArtist | undefined>>;
  albumToRemove: AlbumRemoval | undefined;
  setAlbumToRemove: React.Dispatch<React.SetStateAction<AlbumRemoval | undefined>>;
  curation: Pick<
    UseQueryResult<GetMusicCuration.Output, PqlError>,
    `data` | `isPending` | `isError` | `isSuccess` | `error`
  > & { refetch: () => void };
  albumQuery: Pick<
    UseQueryResult<GetMusicAlbumCuration.Output, PqlError>,
    `isPending` | `isError` | `error`
  > & { refetch: () => void };
  search: Pick<
    UseMutationResult<
      SearchMusicCatalog_v2.Output,
      PqlError,
      SearchMusicCatalog_v2.Input
    >,
    | `data`
    | `isPending`
    | `isError`
    | `isSuccess`
    | `status`
    | `error`
    | `variables`
    | `mutate`
    | `reset`
  >;
  trackApproval: Pick<
    UseMutationResult<GetMusicCuration.Output, PqlError, SearchTrack>,
    `isPending` | `variables` | `mutate`
  >;
  albumApproval: Pick<
    UseMutationResult<GetMusicCuration.Output, PqlError, SearchAlbum>,
    `isPending` | `variables` | `mutate`
  >;
  artistApproval: Pick<
    UseMutationResult<
      ApproveMusicArtist_v2.Output,
      PqlError,
      { artist: SearchArtist; token?: string }
    >,
    `isPending` | `variables` | `mutate`
  >;
  removeArtist: Pick<
    UseMutationResult<RemoveApprovedMusicArtist.Output, PqlError, ApprovedArtist>,
    `isPending` | `mutate`
  >;
  saveAlbum: Pick<
    UseMutationResult<
      SaveMusicAlbumCuration.Output,
      PqlError,
      SaveMusicAlbumCuration.Input
    >,
    `isPending` | `mutate`
  >;
  removeAlbum: Pick<
    UseMutationResult<SaveMusicAlbumCuration.Output, PqlError, AlbumRemoval>,
    `isPending` | `mutate`
  >;
  initialAlbumSelectedTrackIds?: string[];
  closeAlbum: () => boolean;
  toggleAlbum: (id: string, surface: ExpandedAlbum[`surface`], rowId: string) => void;
  closeSearch: () => void;
  leaveSearchEditor: () => boolean;
  album: GetMusicAlbumCuration.Output | undefined;
  onAlbumDirtyChange: (dirty: boolean) => void;
}

export default function useMusicCuration({
  personId,
  client,
  onUnsavedChangesChange,
}: {
  personId: string;
  client: MusicCurationClient;
  onUnsavedChangesChange?: (hasUnsavedChanges: boolean) => void;
}): MusicCurationState {
  const [query, setQuery] = React.useState(``);
  const [searchOpen, setSearchOpen] = React.useState(false);
  const [expandedAlbum, setExpandedAlbum] = React.useState<ExpandedAlbum>();
  const albumSession = React.useRef(0);
  const [albumDirty, setAlbumDirty] = React.useState(false);
  React.useEffect(() => {
    onUnsavedChangesChange?.(albumDirty);
  }, [albumDirty, onUnsavedChangesChange]);
  React.useEffect(
    () => () => {
      onUnsavedChangesChange?.(false);
    },
    [onUnsavedChangesChange],
  );
  const [albumMessage, setAlbumMessage] = React.useState<string>();
  const [artistConfirmation, setArtistConfirmation] = React.useState<{
    artist: SearchArtist;
    confirmation: ArtistConfirmation;
  }>();
  const [artistToRemove, setArtistToRemove] = React.useState<ApprovedArtist>();
  const [albumToRemove, setAlbumToRemove] = React.useState<AlbumRemoval>();
  const requestedArtist = React.useRef<SearchArtist | undefined>(undefined);
  const optimism = useOptimism();
  const albumId = expandedAlbum?.id;
  const curationKey = Key.musicCuration(personId);
  const albumKey = Key.musicAlbumCuration(personId, albumId ?? `closed`);
  const curation = useQuery(curationKey, () =>
    client.getMusicCuration({ childId: personId }),
  );
  const albumQuery = useQuery(
    albumKey,
    () =>
      client.getMusicAlbumCuration({
        childId: personId,
        appleMusicAlbumId: albumId ?? ``,
      }),
    { enabled: !!albumId },
  );
  const search = useMutation(client.searchMusicCatalog);
  const searchAgain = (): void => {
    const term = search.variables?.query;
    if (term) search.mutate({ childId: personId, query: term, limit: 10 });
  };
  const onCurationChanged = (next: GetMusicCuration.Output): void => {
    optimism.update(curationKey, next);
    searchAgain();
  };
  const trackApproval = useMutation(
    (track: SearchTrack) =>
      client.approveMusicTrack({
        childId: personId,
        appleMusicTrackId: track.id,
        preferredAlbumId: track.preferredAlbumId,
      }),
    {
      onSuccess: onCurationChanged,
      invalidating: [curationKey],
      toast: {
        loading: `Allowing track…`,
        success: `Track allowed`,
        error: `Couldn't allow track`,
      },
    },
  );
  const albumApproval = useMutation(
    (album: SearchAlbum) =>
      client.approveMusicAlbum({ childId: personId, appleMusicAlbumId: album.id }),
    {
      onSuccess: onCurationChanged,
      invalidating: [curationKey],
      toast: {
        loading: `Allowing album…`,
        success: `Album allowed`,
        error: `Couldn't allow album`,
      },
    },
  );
  const artistApproval = useMutation(
    ({ artist, token }: { artist: SearchArtist; token?: string }) => {
      requestedArtist.current = artist;
      return client.approveMusicArtist({
        childId: personId,
        appleMusicArtistId: artist.id,
        confirmationToken: token,
      });
    },
    {
      onSuccess: (result) => {
        if (
          result.status === `confirmationRequired` &&
          result.confirmation &&
          requestedArtist.current
        ) {
          optimism.update(curationKey, result.curation);
          setSearchOpen(false);
          setArtistConfirmation({
            artist: requestedArtist.current,
            confirmation: result.confirmation,
          });
        } else if (result.status === `updated`) {
          setArtistConfirmation(undefined);
          onCurationChanged(result.curation);
          toast.success(`Artist allowed`);
        }
      },
      onError: (error) => toast.error(error.userMessage ?? `Couldn't allow artist`),
      invalidating: [curationKey],
    },
  );
  const removeArtist = useMutation(
    (artist: ApprovedArtist) =>
      client.removeApprovedMusicArtist({
        childId: personId,
        appleMusicArtistId: artist.id,
      }),
    {
      onSuccess: () => {
        setArtistToRemove(undefined);
        searchAgain();
        toast.success(`Artist removed`);
      },
      onError: (error) => toast.error(error.userMessage ?? `Couldn't remove artist`),
      invalidating: [curationKey],
    },
  );
  const onAlbumChanged = (
    result: SaveMusicAlbumCuration.Output,
    successMessage: string,
  ): void => {
    optimism.update(curationKey, result.curation);
    optimism.update(Key.musicAlbumCuration(personId, result.album.id), result.album);
    const editingAnotherAlbum =
      expandedAlbum !== undefined && expandedAlbum.id !== result.album.id;
    if (result.status !== `updated`) {
      const message =
        result.status === `conflict`
          ? `This selection changed elsewhere. The checklist has been refreshed; review it before saving again.`
          : `This album is now allowed through ${result.album.governingArtistName ?? `an allowed artist`}. Remove that artist first to change the album.`;
      if (editingAnotherAlbum) {
        toast.error(
          result.status === `conflict`
            ? `The music library changed elsewhere. Review it before trying again.`
            : message,
        );
        return;
      }
      const stillInLibrary = result.curation.albums.some(
        (entry) => entry.id === result.album.id,
      );
      const matchingSearchRow =
        expandedAlbum?.surface === `search` && expandedAlbum.id === result.album.id;
      if (matchingSearchRow || stillInLibrary) {
        setAlbumMessage(message);
        if (!matchingSearchRow && expandedAlbum?.id !== result.album.id) {
          setExpandedAlbum({
            id: result.album.id,
            surface: `library`,
            rowId: result.album.id,
            session: ++albumSession.current,
          });
        }
      } else {
        setAlbumMessage(undefined);
        setExpandedAlbum(undefined);
        setAlbumDirty(false);
        toast.error(message);
      }
    } else {
      if (!editingAnotherAlbum) {
        setAlbumMessage(undefined);
        setExpandedAlbum(undefined);
        setAlbumDirty(false);
      }
      searchAgain();
      toast.success(successMessage);
    }
  };
  const saveAlbum = useMutation(client.saveMusicAlbumCuration, {
    onSuccess: (result) => onAlbumChanged(result, `Music selection saved`),
    onError: (error) => toast.error(error.userMessage ?? `Couldn't save music selection`),
    invalidating: [curationKey],
  });
  const removeAlbum = useMutation(
    ({ album, revision }: AlbumRemoval) =>
      client.saveMusicAlbumCuration({
        childId: personId,
        appleMusicAlbumId: album.id,
        expectedRevision: revision,
        selectedTrackIds: [],
      }),
    {
      onSuccess: (result) => {
        setAlbumToRemove(undefined);
        onAlbumChanged(result, `Album removed`);
      },
      onError: (error) => toast.error(error.userMessage ?? `Couldn't remove album`),
      invalidating: [curationKey],
    },
  );
  const closeAlbum = (): boolean => {
    if (saveAlbum.isPending) return false;
    if (albumDirty && !window.confirm(`Discard your unsaved track changes?`))
      return false;
    setExpandedAlbum(undefined);
    setAlbumDirty(false);
    setAlbumMessage(undefined);
    return true;
  };
  const toggleAlbum = (
    id: string,
    surface: ExpandedAlbum[`surface`],
    rowId: string,
  ): void => {
    if (saveAlbum.isPending) return;
    if (
      expandedAlbum?.id === id &&
      expandedAlbum.surface === surface &&
      expandedAlbum.rowId === rowId
    ) {
      closeAlbum();
      return;
    }
    if (albumDirty && !window.confirm(`Discard your unsaved track changes?`)) return;
    setExpandedAlbum({ id, surface, rowId, session: ++albumSession.current });
    setAlbumDirty(false);
    setAlbumMessage(undefined);
  };
  const closeSearch = (): void => {
    if (expandedAlbum?.surface === `search` && !closeAlbum()) return;
    setSearchOpen(false);
  };
  const leaveSearchEditor = (): boolean =>
    expandedAlbum?.surface !== `search` || closeAlbum();
  const album = albumQuery.data?.id === albumId ? albumQuery.data : undefined;
  const editorSession = expandedAlbum?.session;
  const onAlbumDirtyChange = React.useCallback(
    (dirty: boolean) => {
      if (editorSession === albumSession.current) setAlbumDirty(dirty);
    },
    [editorSession],
  );
  return {
    query,
    setQuery,
    searchOpen,
    setSearchOpen,
    expandedAlbum,
    albumMessage,
    artistConfirmation,
    setArtistConfirmation,
    artistToRemove,
    setArtistToRemove,
    albumToRemove,
    setAlbumToRemove,
    curation,
    albumQuery,
    search,
    trackApproval,
    albumApproval,
    artistApproval,
    removeArtist,
    saveAlbum,
    removeAlbum,
    closeAlbum,
    toggleAlbum,
    closeSearch,
    leaveSearchEditor,
    album,
    onAlbumDirtyChange,
  };
}
