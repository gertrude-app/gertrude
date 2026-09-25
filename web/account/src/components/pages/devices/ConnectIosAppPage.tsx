import { Banner, Button, Input } from '@gertrude/ui';
import cx from 'clsx';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { PersonRelationship } from '#/components/types';
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

interface ChoiceRowProps {
  group: string;
  value: string;
  label: string;
  selected: boolean;
  onSelect: () => void;
  disabled?: boolean;
  disabledMessage?: string;
}

const ChoiceRow: React.FC<ChoiceRowProps> = ({
  group,
  value,
  label,
  selected,
  onSelect,
  disabled = false,
  disabledMessage,
}) => (
  <label
    title={disabledMessage}
    className={cx(
      `flex min-h-10 items-center gap-2.5 rounded-lg border px-3 py-2 text-sm transition-colors focus-within:ring-2 focus-within:ring-violet-300`,
      selected ? `border-violet-400 bg-violet-50` : `border-stone-200 bg-white`,
      disabled
        ? `cursor-not-allowed opacity-50`
        : `cursor-pointer hover:border-stone-300`,
    )}
  >
    <input
      type="radio"
      name={group}
      value={value}
      checked={selected}
      onChange={onSelect}
      disabled={disabled}
      aria-label={disabledMessage ? `${label}. ${disabledMessage}` : undefined}
      className="h-4 w-4 shrink-0 accent-violet-600"
    />
    <span className="font-medium text-stone-900">{label}</span>
  </label>
);

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
    <div className="flex min-h-screen items-center justify-center bg-stone-50 xs:[background-image:url(/dot-noise-pattern.svg),url(/bg.svg)] xs:[background-size:1440px_1440px,cover] xs:[background-repeat:repeat,no-repeat]">
      <form
        onSubmit={handleSubmit}
        className="flex min-h-screen w-full flex-col bg-white shadow-stone-500/20 xs:my-8 xs:min-h-0 xs:max-w-[420px] xs:overflow-hidden xs:rounded-2xl xs:border xs:border-stone-200 xs:shadow-2xl"
      >
        <div className="relative px-5 py-8 text-center">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute inset-0 [background-image:url(/dot-noise-pattern.svg),radial-gradient(ellipse_at_center,rgba(196,180,255,0.16)_0%,transparent_75%),url(/bg.svg)] [background-position:center,center,center] [background-size:1440px_1440px,cover,cover] [mask-image:radial-gradient(ellipse_50%_50%_at_center,black_0%,transparent_100%)]"
          />
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
              <div className="flex flex-col gap-1.5">
                {people.map((person) => (
                  <ChoiceRow
                    key={person.id}
                    group="device-person"
                    value={person.id}
                    label={person.name}
                    selected={selected === person.id}
                    onSelect={() => setSelected(person.id)}
                  />
                ))}
                <ChoiceRow
                  group="device-person"
                  value={NEW_PERSON}
                  label="Add someone new"
                  selected={selected === NEW_PERSON}
                  onSelect={() => setSelected(NEW_PERSON)}
                />
              </div>
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
                  <div
                    role="radiogroup"
                    aria-labelledby={relationshipLabelId}
                    className="flex flex-col gap-1.5"
                  >
                    <ChoiceRow
                      group="new-person-relationship"
                      value="child"
                      label="Your child"
                      selected={relationship === `child`}
                      onSelect={() => setRelationship(`child`)}
                    />
                    <ChoiceRow
                      group="new-person-relationship"
                      value="peer"
                      label="A spouse, friend, or peer"
                      selected={relationship === `peer`}
                      onSelect={() => setRelationship(`peer`)}
                    />
                    <ChoiceRow
                      group="new-person-relationship"
                      value="self"
                      label="Yourself"
                      selected={relationship === `self`}
                      onSelect={() => setRelationship(`self`)}
                      disabled={selfRelationshipUnavailable}
                      disabledMessage={
                        selfRelationshipUnavailable
                          ? selfRelationshipUnavailableMessage
                          : undefined
                      }
                    />
                  </div>
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
    </div>
  );
};

export default ConnectIosAppPage;
