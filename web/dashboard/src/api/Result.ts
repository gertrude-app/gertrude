import { GraphQLError } from 'graphql';

export type ResultData<T, E> /* */ =
  | { type: 'success'; value: T }
  | { type: 'error'; error: E };

type ExtractActionableError = (errors: GraphQLError[]) => ActionableApiError | undefined;

export default class Result<T, E> {
  private constructor(public data: ResultData<T, E>) {}

  public static true(): Result<true, never> {
    return Result.success(true);
  }

  public static success<T>(value: T): Result<T, never> {
    return new Result<T, never>({ type: `success`, value });
  }

  public static error<E>(error: E): Result<never, E> {
    return new Result<never, E>({ type: `error`, error });
  }

  public static unexpectedError(): Result<never, ApiError> {
    return Result.error({ type: `non_actionable` });
  }

  public static merge<TA, TB, E>(
    a: Result<TA, E>,
    b: Result<TB, E>,
  ): Result<[TA, TB], E> {
    if (a.data.type === `error`) {
      return Result.error(a.data.error);
    } else if (b.data.type === `error`) {
      return Result.error(b.data.error);
    } else {
      return Result.success([a.data.value, b.data.value]);
    }
  }

  public with(config: {
    success?: (value: T) => unknown;
    error?: (error: E) => unknown;
  }): void {
    this.mapBoth({
      success: config.success ?? ((value) => value),
      error: config.error ?? ((error) => error),
    });
  }

  public withError(handler: (error: E) => void): void {
    return this.with({ error: handler });
  }

  public map<NewT>(transform: (value: T) => NewT): Result<NewT, E> {
    if (this.data.type === `success`) {
      return Result.success(transform(this.data.value));
    } else {
      return Result.error(this.data.error);
    }
  }

  public mapBoth<NewT, NewE>(config: {
    success: (value: T) => NewT;
    error: (error: E) => NewE;
  }): Result<NewT, NewE> {
    if (this.data.type === `success`) {
      return Result.success(config.success(this.data.value));
    } else {
      return Result.error(config.error(this.data.error));
    }
  }

  public mapApi<NewT>(
    mapSuccess: (value: T) => NewT,
    extractActionable?: ExtractActionableError,
  ): Result<NewT, ApiError> {
    return this.mapBoth({
      success: mapSuccess,
      error: (error) => toApiError(error, extractActionable),
    });
  }

  public valueOrThrow(): T {
    if (this.data.type === `success`) {
      return this.data.value;
    }
    throw this.data.error;
  }

  public get value(): T | undefined {
    if (this.data.type === `success`) {
      return this.data.value;
    }
    return undefined;
  }

  public get error(): E | undefined {
    if (this.data.type === `error`) {
      return this.data.error;
    }
    return undefined;
  }

  public get isSuccess(): boolean {
    return this.data.type === `success`;
  }

  public get isError(): boolean {
    return this.data.type === `error`;
  }

  public mapError<NewError>(transform: (error: E) => NewError): Result<T, NewError> {
    if (this.data.type === `error`) {
      return Result.error(transform(this.data.error));
    } else {
      // @ts-ignore
      return Result.success<T, NewError>({ type: `success`, value: this.data.value });
    }
  }

  public mapErrorToApi(extractActionable?: ExtractActionableError): Result<T, ApiError> {
    return this.mapApi((value) => value, extractActionable);
  }

  public mapErrorToVoid(): Result<T, void> {
    return this.mapError(() => void 0);
  }
}

// helpers

function toApiError(
  error: unknown,
  extractActionable?: ExtractActionableError,
): ApiError {
  if (!isGraphQLErrorArray(error)) {
    return {
      type: `non_actionable`,
      rawErrors: toNonActionableRawErrors(error),
    };
  }

  // if the server sends an error containing this special string, force relogin
  if (error.some((e) => e.message.includes(`@client:relogin`))) {
    return { type: `auth_failed` };
  }

  // mostly likely lack of internet, though CORS errors produce the same error
  if (error.some((e) => e.message.includes(`Failed to fetch`))) {
    return { type: `no_internet` };
  }

  // we're done with well-known, common api errors, so now give the caller
  // a chance to apply special logic to extract a user-actionable error
  const actionable = (extractActionable ?? (() => {}))(error);
  if (actionable) {
    return actionable;
  }

  return {
    type: `non_actionable`,
    rawErrors: toNonActionableRawErrors(error),
  };
}

function isGraphQLErrorArray(something: unknown): something is GraphQLError[] {
  return (
    Array.isArray(something) && something.every((item) => item instanceof GraphQLError)
  );
}

function toNonActionableRawErrors(error: unknown): string[] | undefined {
  if (Array.isArray(error)) {
    return error.map(String);
  }
  return [String(error)];
}
