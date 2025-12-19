import isEqual from 'lodash.isequal';
import type { PqlError, RequestState } from '@dash/types';

export class Req {
  static succeed<T>(payload: T): RequestState<T> {
    return { state: `succeeded`, payload };
  }

  static fail(error: PqlError | undefined = undefined): RequestState<never> {
    return { state: `failed`, error };
  }

  static ongoing<T, E>(): RequestState<T, E> {
    return { state: `ongoing` };
  }

  static idle<T, E>(): RequestState<T, E> {
    return { state: `idle` };
  }

  static payload<T, E>(req: RequestState<T, E> | undefined): T | undefined {
    if (req && req.state === `succeeded`) {
      return req.payload;
    }
    return undefined;
  }
}

export function revert<T extends { id: UUID }>({ original }: Editable<T>): Editable<T> {
  return editable(original);
}

export function commit<T extends { id: UUID }>({ draft }: Editable<T>): Editable<T> {
  return { ...editable(draft), isNew: false };
}

export function isEditable<T extends { id: UUID }>(input: unknown): input is Editable<T> {
  if (typeof input !== `object` || input === null) {
    return false;
  } else if (!(`original` in input) || !(`draft` in input)) {
    return false;
  }
  const entity = (input as any).original;
  return typeof entity === `object` && entity !== null && isUUID(entity.id);
}

export function isUUID(input: unknown): input is UUID {
  return (
    typeof input === `string` &&
    input.length === 36 &&
    input.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) !==
      null
  );
}

export function editable<T extends { id: UUID }>(
  original: T,
  isNew?: boolean,
): Editable<T> {
  return {
    id: original.id,
    original,
    draft: JSON.parse(JSON.stringify(original)),
    isNew,
  };
}

export function isDirty<T extends { id: UUID }>(
  editable: Editable<T>,
  prop?: keyof T,
): boolean {
  const draft = prop ? editable.draft[prop] : editable.draft;
  const original = prop ? editable.original[prop] : editable.original;
  return !isEqual(original, draft);
}
