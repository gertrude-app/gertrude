// @see https://github.com/microsoft/TypeScript/issues/4753
export function enumValues<T extends string>(enumObj: {
  [key: string]: T;
}): IterableIterator<T>;

export function enumValues<T extends string | number>(enumObj: {
  [key: string]: T;
}): IterableIterator<Exclude<T, string>>;

export function* enumValues<T>(enumObj: { [key: string]: T }): IterableIterator<T> {
  let isStringEnum = true;
  for (const property in enumObj) {
    if (typeof enumObj[property] === `number`) {
      isStringEnum = false;
      break;
    }
  }
  for (const property in enumObj) {
    if (isStringEnum || typeof enumObj[property] === `number`) {
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      yield enumObj[property]!;
    }
  }
}

type Entries<T> = {
  [K in keyof T]: [K, T[K]];
}[keyof T][];

export function objectEntries<T extends Record<string, unknown>>(obj: T): Entries<T> {
  return Object.entries(obj) as any;
}

export function objectValues<T extends Record<string, unknown>>(
  obj: T,
): Array<T[keyof T]> {
  return Object.values(obj) as any;
}

export function objectKeys<T extends Record<string, unknown>>(obj: T): Array<keyof T> {
  return Object.keys(obj) as any;
}
