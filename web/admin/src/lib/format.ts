export function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString(`en-US`, {
    year: `numeric`,
    month: `short`,
    day: `numeric`,
  });
}

export function unCamelCase(str: string): string {
  return str
    .replace(/([a-z])([A-Z])/g, `$1 $2`)
    .replace(/([A-Z]+)([A-Z][a-z])/g, `$1 $2`)
    .toLowerCase()
    .replace(/^\w/, (c) => c.toUpperCase());
}
