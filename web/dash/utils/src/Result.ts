export type ResultData<T, E> /* */ =
  | { type: 'success'; value: T }
  | { type: 'error'; error: E };

export default class Result<T, E> {
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

  public mapErrorToVoid(): Result<T, void> {
    return this.mapError(() => void 0);
  }
}
