type UUID = string;

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
