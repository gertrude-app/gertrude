export function isoToDateInput(iso: string): string {
  return formatDate(new Date(iso), `dateInput`);
}

export function formatDate(
  date: Date,
  style: 'long' | 'medium' | 'short' | 'url' | 'dateInput',
): string {
  if (style === `short`) {
    return date.toLocaleDateString();
  }

  if (style === `url`) {
    return [
      `${date.getMonth() + 1}`.padStart(2, `0`),
      `${date.getDate()}`.padStart(2, `0`),
      `${date.getFullYear()}`,
    ].join(`-`);
  }

  if (style === `dateInput`) {
    return [
      `${date.getFullYear()}`,
      `${date.getMonth() + 1}`.padStart(2, `0`),
      `${date.getDate()}`.padStart(2, `0`),
    ].join(`-`);
  }

  return [
    date.toLocaleDateString(`en-US`, { weekday: `long` }),
    `, `,
    date.toLocaleDateString(`en-US`, { month: style === `long` ? `long` : `short` }),
    ` `,
    date.getDate(),
    `, `,
    date.getFullYear(),
  ].join(``);
}
