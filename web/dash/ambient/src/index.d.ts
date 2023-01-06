type UUID = string;
type EmailAddress = string;
type ISODateString = string;

type Editable<T extends { id: UUID }> = {
  isNew?: boolean;
  original: Readonly<T>;
  draft: T;
};

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
