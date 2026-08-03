import { relativeTime } from '@shared/datetime';
import type { PersonCardPerson } from '#/components/types';
import type { GetPeople } from '@shared/pairql/src/account';

export const selfRelationshipUnavailableMessage = `Another protected person is already set to Myself. Change their relationship first.`;

export function toPersonCardPerson(person: GetPeople.Output[number]): PersonCardPerson {
  return {
    id: person.id,
    name: person.name,
    relationship: person.relationship,
    devices: person.devices.map((device) =>
      device.case === `mac`
        ? {
            id: device.id,
            personId: person.id,
            type: `mac`,
            name: device.name,
            macOSVersion: device.macOSVersion,
            modelName: device.modelName,
            modelIdentifier: device.modelIdentifier,
            online: device.online,
          }
        : {
            id: device.id,
            personId: person.id,
            type: device.type,
            iOSVersion: device.iOSVersion,
            modelName: device.modelName,
            modelIdentifier: device.modelIdentifier,
          },
    ),
    screenshot: person.screenshot
      ? {
          url: person.screenshot.url,
          recency: relativeTime(person.screenshot.createdAt),
        }
      : null,
  };
}
