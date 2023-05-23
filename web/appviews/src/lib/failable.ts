export type Failable<T> = { case: 'ok'; value: T } | { case: 'error'; message?: string };

export function valueOf<T>(failable: Failable<T> | undefined): T | undefined {
  return failable?.case === `ok` ? failable.value : undefined;
}

export function error<T>(
  failable: Failable<T>,
): { case: 'error'; message?: string } | undefined {
  return failable.case === `error` ? failable : undefined;
}

export function errorMessage<T>(failable: Failable<T> | undefined): string | undefined {
  return failable?.case === `error` ? failable.message : undefined;
}

export function isError<T>(
  failable: Failable<T>,
): failable is { case: 'error'; message?: string } {
  return failable.case === `error`;
}

export function isOk<T>(failable: Failable<T>): failable is { case: 'ok'; value: T } {
  return failable.case === `ok`;
}
