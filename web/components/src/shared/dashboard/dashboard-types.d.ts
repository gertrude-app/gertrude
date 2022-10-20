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
  | { type: 'not_found' }
  | ActionableApiError
  | { type: 'non_actionable'; rawErrors?: string[] };

type DashboardWidgetData = {
  unlockRequests: Array<{
    id: UUID;
    target: string;
    userName: string;
    comment?: string | null;
    createdAt: string;
  }>;
  users: Array<{
    id: UUID;
    name: string;
    isOnline: boolean;
  }>;
  userActivity: Array<{
    id: UUID;
    userName: string;
    numUnreviewed: number;
  }>;
  userScreenshots: Array<{
    id: UUID;
    userName: string;
    url: string;
    createdAt: string;
  }>;
};
