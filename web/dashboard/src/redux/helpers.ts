import { JSXElementConstructor } from 'react';
import { QueriedProps } from './store';

export class Query {
  static succeed<T extends JSXElementConstructor<any>>(
    props: React.ComponentProps<T>,
  ): QueriedProps<T> {
    return { state: `succeeded`, props };
  }

  static props<T extends JSXElementConstructor<any>>(
    query: QueriedProps<T>,
  ): React.ComponentProps<T> | undefined {
    if (query.state === `succeeded`) {
      return query.props;
    }
    return undefined;
  }
}

export class Req {
  static succeed<T>(payload: T): RequestState<T> {
    return { state: `succeeded`, payload };
  }

  static fail<T, E>(error: E | undefined = undefined): RequestState<T, E> {
    return { state: `failed`, error };
  }

  static ongoing<T, E>(): RequestState<T, E> {
    return { state: `ongoing` };
  }

  static idle<T, E>(): RequestState<T, E> {
    return { state: `idle` };
  }

  static map<T, E, NewT>(
    req: RequestState<T, E>,
    transform: (payload: T) => NewT,
  ): RequestState<NewT, E> {
    if (req.state === `succeeded`) {
      return {
        state: `succeeded`,
        payload: transform(req.payload),
      };
    }
    return req;
  }

  static payload<T, E>(req: RequestState<T, E> | undefined): T | undefined {
    if (req && req.state === `succeeded`) {
      return req.payload;
    }
    return undefined;
  }

  static withPayload<T, E>(
    req: RequestState<T, E> | undefined,
    handler: (payload: T) => unknown,
  ): void {
    if (req && req.state === `succeeded`) {
      handler(req.payload);
    }
  }

  static error<T, E>(req: RequestState<T, E> | undefined): E | undefined {
    if (req && req.state === `failed`) {
      return req.error;
    }
    return undefined;
  }
}

export function toMap<T extends { id: string }>(array: T[]): Record<string, T> {
  return array.reduce<Record<string, T>>((map, item) => {
    map[item.id] = item;
    return map;
  }, {});
}

export function toEditableMap<T extends { id: string }>(
  array: T[],
): Record<string, Editable<T>> {
  return array.reduce<Record<string, Editable<T>>>((map, item) => {
    map[item.id] = toEditable(item);
    return map;
  }, {});
}

export function toEditable<T extends { id: UUID }>(original: T): Editable<T> {
  return { original, draft: JSON.parse(JSON.stringify(original)) };
}

export function isDirty<T extends { id: UUID }>(editable: Editable<T>): boolean {
  return JSON.stringify(editable.original) !== JSON.stringify(editable.draft);
}

export async function spinnerMin<T>(promise: Promise<T>, delayMs = 750): Promise<T> {
  const start = Date.now();
  const result = await promise;
  const elapsed = Date.now() - start;
  if (elapsed >= delayMs) {
    return result;
  }
  return new Promise((res) => setTimeout(() => res(result), delayMs - elapsed));
}

export function notNullish<T>(x: T | null | undefined): x is T {
  return x !== null && x !== undefined;
}
