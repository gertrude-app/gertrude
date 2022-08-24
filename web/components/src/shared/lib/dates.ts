/**
 * long: `Thursday, August 18, 2022`
 * medium: `Thursday, Aug. 18, 2022`
 * short: `8/18/22`
 * url: `08-18-2022`
 */
export function formatDate(
  date: Date,
  style: 'long' | 'medium' | 'short' | 'url',
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

  return [
    date.toLocaleDateString(`en-US`, { weekday: `long` }),
    `, `,
    date.toLocaleDateString(`en-US`, { month: style === `long` ? `long` : `short` }),
    style === `long` ? ` ` : `. `,
    date.getDate(),
    `, `,
    date.getFullYear(),
  ].join(``);
}
