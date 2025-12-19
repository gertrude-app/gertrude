type UUID = string;
type EmailAddress = string;
type ISODateString = string;

type Editable<T extends { id: UUID }> = {
  readonly id: UUID;
  isNew?: boolean;
  original: Readonly<T>;
  draft: T;
};
