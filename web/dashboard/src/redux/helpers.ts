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
}

export function toMap<T extends { id: string }>(array: T[]): Record<string, T> {
  return array.reduce<Record<string, T>>((map, item) => {
    map[item.id] = item;
    return map;
  }, {});
}
