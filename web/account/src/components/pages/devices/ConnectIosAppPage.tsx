import { Banner, Button, Input, RadioList } from '@gertrude/ui';
import cx from 'clsx';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { PersonRelationship } from '#/components/types';
import PairingPageLayout, { PairingHeaderBackground } from './PairingPageLayout';
import DeviceArtwork from '#/components/people/DeviceArtwork';
import { selfRelationshipUnavailableMessage } from '#/lib/people';

type Flow = `blockerConnect` | `blockerSupervise` | `podcasts` | `music`;
type Selection =
  | { type: `existing`; id: string }
  | { type: `new`; name: string; relationship: PersonRelationship };

interface Props {
  flow: Flow;
  device: {
    type: `iPhone` | `iPad`;
    modelName: string;
    modelIdentifier: string;
  };
  people: { id: string; name: string }[];
  initialSelection?:
    | { type: `existing`; id: string }
    | { type: `new`; name: string; relationship?: PersonRelationship };
  selfRelationshipUnavailable?: boolean;
  submitting?: boolean;
  error?: string;
  onSubmit: (selection: Selection) => void;
  onCancel: () => void;
}

const flowDetails: Record<
  Flow,
  { appName: string; shortName: string; icon: string; supervision: boolean }
> = {
  blockerConnect: {
    appName: `Gertrude Blocker`,
    shortName: `Blocker`,
    icon: `/gertrude-app-icons/blocker.webp`,
    supervision: false,
  },
  blockerSupervise: {
    appName: `Gertrude Blocker`,
    shortName: `Blocker`,
    icon: `/gertrude-app-icons/blocker.webp`,
    supervision: true,
  },
  podcasts: {
    appName: `Gertrude Podcasts`,
    shortName: `Podcasts`,
    icon: `/gertrude-app-icons/podcasts.webp`,
    supervision: false,
  },
  music: {
    appName: `Gertrude Music`,
    shortName: `Music`,
    icon: `/gertrude-app-icons/music.webp`,
    supervision: false,
  },
};

const NEW_PERSON = `__new_person__`;

const ConnectIosAppPage: React.FC<Props> = ({
  flow,
  device,
  people,
  initialSelection,
  selfRelationshipUnavailable = false,
  submitting = false,
  error,
  onSubmit,
  onCancel,
}) => {
  const details = flowDetails[flow];
  const [selected, setSelected] = React.useState<string | null>(
    initialSelection?.type === `existing`
      ? initialSelection.id
      : initialSelection?.type === `new` || people.length === 0
        ? NEW_PERSON
        : null,
  );
  const [name, setName] = React.useState(
    initialSelection?.type === `new` ? initialSelection.name : ``,
  );
  const [relationship, setRelationship] = React.useState<PersonRelationship | null>(
    initialSelection?.type === `new` ? (initialSelection.relationship ?? null) : null,
  );
  const relationshipLabelId = React.useId();

  React.useEffect(() => {
    if (selfRelationshipUnavailable && relationship === `self`) {
      setRelationship(null);
    }
  }, [relationship, selfRelationshipUnavailable]);

  const selectedPerson = people.find((person) => person.id === selected);
  const selectedName = selected === NEW_PERSON ? name.trim() : selectedPerson?.name;
  const canSubmit =
    Boolean(selectedName) &&
    (selected !== NEW_PERSON ||
      (relationship !== null &&
        !(relationship === `self` && selfRelationshipUnavailable))) &&
    !submitting;
  const action = details.supervision
    ? selectedName
      ? `Continue setup for ${selectedName}`
      : `Continue setup`
    : selectedName
      ? `Connect ${details.shortName} for ${selectedName}`
      : `Connect ${details.appName}`;

  const handleSubmit = (event: React.FormEvent): void => {
    event.preventDefault();
    if (!canSubmit) return;
    if (selected === NEW_PERSON && relationship) {
      onSubmit({ type: `new`, name: name.trim(), relationship });
    } else if (selectedPerson) {
      onSubmit({ type: `existing`, id: selectedPerson.id });
    }
  };

  return (
    <PairingPageLayout>
      <form onSubmit={handleSubmit} className="flex flex-col">
        <div className="relative px-5 py-8 text-center">
          <PairingHeaderBackground />
          <div
            className="relative flex items-center justify-center gap-4"
            aria-label={`${details.appName} on ${device.modelName}`}
          >
            <img
              src={details.icon}
              alt={details.appName}
              className="h-10 w-10 rounded-xl shadow-sm"
            />
            <svg
              className="h-4 w-10 shrink-0 text-stone-500"
              viewBox="0 0 48 20"
              fill="none"
              aria-hidden="true"
            >
              <path
                d="M2 10h42m-8-8 8 8-8 8"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
            <DeviceArtwork
              device={{
                type: device.type === `iPad` ? `ipad` : `iphone`,
                modelIdentifier: device.modelIdentifier,
              }}
              size="pairing"
            />
          </div>
        </div>

        <fieldset disabled={submitting} className="px-6 pb-6 pt-5">
          <legend className="float-left w-full text-center text-base font-medium text-stone-950">
            Who uses this {device.modelName}?
          </legend>
          <div className="clear-both pt-3">
            {people.length > 0 && (
              <RadioList
                name="device-person"
                ariaLabel={`Who uses this ${device.modelName}?`}
                options={[
                  ...people.map((person) => ({ value: person.id, label: person.name })),
                  { value: NEW_PERSON, label: `Add someone new` },
                ]}
                selected={selected}
                onSelect={setSelected}
              />
            )}

            {selected === NEW_PERSON && (
              <div className={cx(`flex flex-col gap-4`, people.length > 0 && `mt-4`)}>
                <div>
                  <h2
                    id={relationshipLabelId}
                    className="mb-2 text-xs font-medium text-stone-700"
                  >
                    What is their relationship to you?
                  </h2>
                  <RadioList
                    name="new-person-relationship"
                    ariaLabelledBy={relationshipLabelId}
                    options={[
                      { value: `child`, label: `Your child` },
                      { value: `peer`, label: `A spouse, friend, or peer` },
                      {
                        value: `self`,
                        label: `Yourself`,
                        disabled: selfRelationshipUnavailable,
                        disabledMessage: selfRelationshipUnavailable
                          ? selfRelationshipUnavailableMessage
                          : undefined,
                      },
                    ]}
                    selected={relationship}
                    onSelect={(value) => setRelationship(value as PersonRelationship)}
                  />
                  {relationship === `self` && (
                    <Banner variant="warning" className="mt-4">
                      Gertrude works best when someone you trust manages your settings and
                      reviews your activity.
                    </Banner>
                  )}
                </div>
                <Input
                  type="text"
                  value={name}
                  setValue={setName}
                  label="Their name"
                  placeholder="Enter a name"
                  autoComplete="off"
                  disabled={submitting}
                  required
                />
              </div>
            )}

            {error && (
              <div className="mt-4" role="alert">
                <Banner variant="error">{error}</Banner>
              </div>
            )}
          </div>
        </fieldset>
        <div className="flex flex-col gap-1.5 border-t border-stone-200 bg-stone-50 px-6 py-5">
          <Button
            type="submit"
            variant="primary"
            icon={ArrowRightIcon}
            iconPosition="right"
            disabled={!canSubmit}
            loading={submitting}
          >
            {action}
          </Button>
          <Button type="button" variant="ghost" onClick={onCancel} disabled={submitting}>
            Cancel
          </Button>
        </div>
      </form>
    </PairingPageLayout>
  );
};

export default ConnectIosAppPage;
