export function inflect(word: string, count: number): string {
  if (count === 1) {
    return word;
  }
  return `${word}s`;
}

export function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
