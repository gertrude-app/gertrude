import { useQueryClient } from '@tanstack/react-query';
import React from 'react';
import type { ConnectMacState } from './ConnectMacModal';
import type ConnectMacModal from './ConnectMacModal';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';

type Person = { id: string; name: string };

export function useConnectMac(closeOnChange?: unknown): {
  connectMac: (people: Person[]) => void;
  modalProps: React.ComponentProps<typeof ConnectMacModal>;
} {
  const queryClient = useQueryClient();
  const [open, setOpen] = React.useState(false);
  const [choices, setChoices] = React.useState<Person[]>([]);
  const [person, setPerson] = React.useState<Person>();
  const [trialStarted, setTrialStarted] = React.useState(false);

  React.useEffect(() => {
    setOpen(false);
  }, [closeOnChange]);
  const createCode = useMutation(liveClient.createMacConnectionCode);
  const startTrial = useMutation(liveClient.startAccountFullTrial, {
    invalidating: [Key.accountBilling],
    toast: {
      loading: `Starting trial…`,
      success: `Full trial started`,
      error: `Couldn't start the trial`,
    },
    onSuccess: () => setTrialStarted(true),
  });

  const reset = (): void => {
    createCode.reset();
    startTrial.reset();
    setTrialStarted(false);
  };

  const output = createCode.data;
  const state: ConnectMacState = !person
    ? { case: `choosePerson`, people: choices }
    : createCode.isPending
      ? { case: `instructions`, requesting: true }
      : createCode.isError
        ? {
            case: `error`,
            message:
              createCode.error.userMessage ??
              `Couldn't create a connection code. Check your connection and try again.`,
          }
        : output?.gate === `trialRequired` && !trialStarted
          ? { case: `trialRequired`, startingTrial: startTrial.isPending }
          : output?.gate === `planUpgradeRequired`
            ? { case: `planUpgradeRequired` }
            : output?.gate === `subscriptionFixRequired`
              ? { case: `subscriptionFixRequired` }
              : output
                ? { case: `ready`, code: output.code }
                : { case: `instructions` };

  return {
    connectMac: (people) => {
      reset();
      setChoices(people);
      setPerson(people.length === 1 ? people[0] : undefined);
      setOpen(true);
    },
    modalProps: {
      open,
      onOpenChange: (isOpen) => {
        setOpen(isOpen);
        if (!isOpen) {
          reset();
          void queryClient.invalidateQueries({ queryKey: Key.people.segments });
          void queryClient.invalidateQueries({ queryKey: Key.devices.segments });
          void queryClient.invalidateQueries({ queryKey: Key.accountSetup.segments });
        }
      },
      personName: person?.name ?? ``,
      state,
      onChoosePerson: (personId) =>
        setPerson(choices.find((choice) => choice.id === personId)),
      onRequestCode: () => person && createCode.mutate({ personId: person.id }),
      onStartTrial: () => startTrial.mutate(undefined),
    },
  };
}
