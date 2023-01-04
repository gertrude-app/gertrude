type UUID = string;
type EmailAddress = string;
type ISODateString = string;

type Editable<T extends { id: UUID }> = {
  isNew?: boolean;
  original: Readonly<T>;
  draft: T;
};

type PqlError = {
  // todo, deal with these
  type?: 'not_found' | 'non_actionable' | 'no_internet' | 'auth_failed' | 'actionable';
  debugMessage: string;
  userFacingMessage?: string;
  errorId?: UUID;
  clientRequestId?: UUID;
  serverRequestId?: UUID;
};

type RequestState<T = void, E = PqlError> =
  | { state: 'idle' }
  | { state: 'ongoing' }
  | { state: 'failed'; error?: E }
  | { state: 'succeeded'; payload: T };

// TODO: remove me
type ActionableApiError = {
  type: 'actionable';
  message?: string;
};

// TODO: remove me
type ApiError =
  | { type: 'auth_failed' }
  | { type: 'no_internet' }
  | { type: 'not_found' }
  | ActionableApiError
  | { type: 'non_actionable'; rawErrors?: string[] };
