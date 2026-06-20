const macImageBaseUrl = `https://parents.gertrude.app/macs`;

export const macImageUrl = (modelIdentifier: string): string =>
  `${macImageBaseUrl}/${encodeURIComponent(modelIdentifier)}.png`;
