type UUID = string;
type EmailAddress = string;

type Editable<T extends { id: UUID }> = {
  isNew?: boolean;
  original: Readonly<T>;
  draft: T;
};

type RequestState<T = void, E = ApiError> =
  | { state: 'idle' }
  | { state: 'ongoing' }
  | { state: 'failed'; error?: E }
  | { state: 'succeeded'; payload: T };

type ActionableApiError = {
  type: 'actionable';
  message?: string;
};

type ApiError =
  | { type: 'auth_failed' }
  | { type: 'no_internet' }
  | ActionableApiError
  | { type: 'non_actionable'; rawErrors?: string[] };

type SingleAppScope =
  | { type: 'bundleId'; bundleId: string }
  | { type: 'identifiedAppSlug'; identifiedAppSlug: string };

type AppScope =
  | { type: `webBrowsers` }
  | { type: `unrestricted` }
  | { type: `single`; single: SingleAppScope };

type Key =
  | { type: 'domain'; domain: string; scope: AppScope }
  | { type: 'anySubdomain'; domain: string; scope: AppScope }
  | { type: 'domainRegex'; pattern: string; scope: AppScope }
  | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
  | { type: 'path'; path: string; scope: AppScope } // deprecated
  | { type: 'skeleton'; scope: SingleAppScope };

type KeyRecord = {
  id: UUID;
  key: Key;
  comment?: string | null;
  expiration?: string | null;
};

type Keychain = {
  id: UUID;
  name: string;
  authorId: UUID;
  description: string | null;
  isPublic: boolean;
  keyRecords: Record<UUID, KeyRecord>;
};
