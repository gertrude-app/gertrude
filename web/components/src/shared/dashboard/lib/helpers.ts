export function writable<T>(input: T): T {
  return JSON.parse(JSON.stringify(input));
}
