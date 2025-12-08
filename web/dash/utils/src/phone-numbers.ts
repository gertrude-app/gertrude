const COUNTRY_CODES_WITH_TRUNK_PREFIX = [`33`, `44`, `49`, `81`];

export function parseE164(phoneNumber: string | undefined): string | null {
  if (!phoneNumber) {
    return null;
  }
  const hadPlus = phoneNumber.match(/^\s?\+/) !== null;
  const digits = phoneNumber.replace(/\D/g, ``);
  if (digits.length === 10 && !hadPlus) {
    return `+1${digits}`;
  } else if (digits.length < 7 || digits.length > 15) {
    return null;
  } else {
    let result = `+${digits}`;
    for (const countryCode of COUNTRY_CODES_WITH_TRUNK_PREFIX) {
      if (result.startsWith(`+${countryCode}0`)) {
        result = `+${countryCode}${result.slice(countryCode.length + 2)}`;
        break;
      }
    }
    return result;
  }
}

export function prettyE164(phoneNumber: string): string {
  const match = phoneNumber.match(/^\+1(\d{3})(\d{3})(\d{4})$/);
  if (!match) {
    return phoneNumber;
  }
  return `(${match[1]}) ${match[2]}-${match[3]}`;
}
