import type { PqlError } from './PqlError';

export type ResultData<T, E = PqlError> =
  | { type: `success`; value: T }
  | { type: `error`; error: E };

export default class Result<T, E = PqlError> {
  protected constructor(public data: ResultData<T, E>) {}

  public static true(): Result<true, never> {
    return Result.success(true);
  }

  public static success<T>(value: T): Result<T, never> {
    return new Result<T, never>({ type: `success`, value });
  }

  public static error<E>(error: E): Result<never, E> {
    return new Result<never, E>({ type: `error`, error });
  }

  public static unexpectedError(
    id: string,
    debugMessage?: string,
  ): Result<never, PqlError> {
    return Result.error({
      id,
      type: `clientError`,
      debugMessage: debugMessage ?? `[no debug message]`,
      isPqlError: true,
    });
  }

  public static resolveUnexpected(
    id: string,
    debugMessage?: string,
  ): Promise<Result<never, PqlError>> {
    return Promise.resolve(this.unexpectedError(id, debugMessage));
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
    if (this.data.type === `success`) {
      config.success?.(this.data.value);
    } else {
      config.error?.(this.data.error);
    }
  }

  public reduce<K>(config: { success: (value: T) => K; error: (error: E) => K }): K {
    if (this.data.type === `success`) {
      return config.success(this.data.value);
    } else {
      return config.error(this.data.error);
    }
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

  public mapOrThrow<K>(mapFn: (value: T) => K): K {
    return this.reduce({
      success: mapFn,
      error: (error) => {
        throw error;
      },
    });
  }

  public valueOrThrow(): T {
    if (this.data.type === `success`) {
      return this.data.value;
    }
    throw this.data.error;
  }

  public unwrap(): T {
    return this.valueOrThrow();
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

  public mapError<NewE>(transform: (error: E) => NewE): Result<T, NewE> {
    if (this.data.type === `error`) {
      return Result.error(transform(this.data.error));
    } else {
      return Result.success(this.data.value);
    }
  }

  public withError(handler: (error: E) => void): void {
    return this.with({ error: handler });
  }

  public mapErrorToVoid(): Result<T, void> {
    return this.mapError(() => void 0);
  }
}
