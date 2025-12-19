export function inflect(word: string, count: number): string {
  if (count === 1) {
    return word;
  }
  return `${word}s`;
}

export function posessive(name: string): string {
  if (name.trim() === ``) {
    return name;
  }

  if (name.endsWith(`s`)) {
    return `${name}’`;
  }
  return `${name}’s`;
}

export function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

export function pastTense(s: string): string {
  const lastLetter = s.charAt(s.length - 1);
  switch (lastLetter) {
    case `e`:
      return `${s}d`;
    case `y`:
      return `${s.slice(0, -1)}ied`;
    case `d`:
      return `${s.slice(0, -1)}t`;
    default:
      return `${s}ed`;
  }
}
