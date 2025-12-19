import type { AddressType } from './edit';
import { domain } from '.';

export function address(input: string, type: AddressType): boolean {
  switch (type) {
    case `standard`:
    case `strict`:
      return domain.registrable(input) !== null;
    case `ip`:
      return domain.isIpAddress(input);
    case `domainRegex`:
      return (
        input.includes(`*`) && domain.registrable(input.replace(/\*/g, `a`)) !== null
      );
  }
}
