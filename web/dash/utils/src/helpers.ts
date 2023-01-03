// TODO: i should be able to remove this, required only for graphql
export function writable<T>(input: T): T {
  return JSON.parse(JSON.stringify(input));
}

export function newestFirst<T extends { createdAt: string }>(a: T, b: T): number {
  return a.createdAt < b.createdAt ? 1 : -1;
}
