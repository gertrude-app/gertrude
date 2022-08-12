import { DashboardError } from './errors';

export type ResultData<T, E = DashboardError> /* */ =
  | { type: 'success'; value: T }
  | { type: 'error'; error: E };

export default class Result<T, E = DashboardError> {
  private constructor(public data: ResultData<T, E>) {}

  public static success<T, E = DashboardError>(value: T): Result<T, E> {
    return new Result<T, E>({ type: `success`, value });
  }

  public static error<T, E = DashboardError>(error: E): Result<T, E> {
    return new Result<T, E>({ type: `error`, error });
  }

  public get result(): ResultData<T, E> {
    return this.data;
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
