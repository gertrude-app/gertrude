import { Banner, Button, HStack, Modal, RadioList, Text, VStack } from '@gertrude/ui';
import {
  CheckIcon,
  CopyIcon,
  DownloadIcon,
  ExternalLinkIcon,
  LinkIcon,
} from 'lucide-react';
import React from 'react';
import InstructionStep from './InstructionStep';
import PromoCard from '#/components/PromoCard';

export type ConnectMacState =
  | { case: `choosePerson`; people: { id: string; name: string }[] }
  | { case: `instructions`; requesting?: boolean }
  | { case: `error`; message: string }
  | { case: `trialRequired`; startingTrial?: boolean }
  | { case: `planUpgradeRequired` }
  | { case: `subscriptionFixRequired` }
  | { case: `ready`; code: number };

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  personName: string;
  state: ConnectMacState;
  onChoosePerson?: (personId: string) => void;
  onRequestCode: () => void;
  onStartTrial: () => void;
};

const ConnectMacModal: React.FC<Props> = ({
  open,
  onOpenChange,
  personName,
  state,
  onChoosePerson,
  onRequestCode,
  onStartTrial,
}) => {
  const [copied, setCopied] = React.useState(false);
  const [chosenPersonId, setChosenPersonId] = React.useState<string>();
  const busy =
    (state.case === `instructions` && state.requesting === true) ||
    (state.case === `trialRequired` && state.startingTrial === true);
  const promoState =
    state.case === `trialRequired` || state.case === `planUpgradeRequired`;

  React.useEffect(() => {
    setCopied(false);
    setChosenPersonId(undefined);
  }, [open, state.case]);

  const handleCopy = async (code: string): Promise<void> => {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
    } catch {
      setCopied(false);
    }
  };

  let title = `Connect a Mac for ${personName}`;
  let description = `Install Gertrude on the Mac, then connect it with a one-time code.`;
  let body: React.ReactNode;
  let footer: React.ReactNode;

  switch (state.case) {
    case `choosePerson`:
      title = `Connect a Mac`;
      description = `Who will use this Mac?`;
      body = (
        <RadioList
          ariaLabel="Who will use this Mac?"
          options={state.people.map((person) => ({
            value: person.id,
            label: person.name,
          }))}
          selected={chosenPersonId}
          onSelect={setChosenPersonId}
        />
      );
      footer = (
        <>
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            type="button"
            variant="primary"
            disabled={chosenPersonId === undefined}
            onClick={() => chosenPersonId && onChoosePerson?.(chosenPersonId)}
          >
            Continue
          </Button>
        </>
      );
      break;
    case `instructions`:
      body = <ConnectionInstructions personName={personName} />;
      footer = (
        <>
          <Button
            type="button"
            variant="ghost"
            disabled={state.requesting}
            onClick={() => onOpenChange(false)}
          >
            Cancel
          </Button>
          <Button
            type="button"
            variant="primary"
            loading={state.requesting}
            onClick={onRequestCode}
          >
            Get connection code
          </Button>
        </>
      );
      break;
    case `error`:
      body = (
        <VStack gap={4}>
          <ConnectionInstructions personName={personName} />
          <Banner variant="error">{state.message}</Banner>
        </VStack>
      );
      footer = (
        <>
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button type="button" variant="primary" onClick={onRequestCode}>
            Try again
          </Button>
        </>
      );
      break;
    case `trialRequired`:
      title = `Start a Full trial`;
      description = `Connecting Gertrude on a Mac requires the Full plan.`;
      body = <TrialRequiredContent />;
      footer = (
        <>
          <Button
            type="button"
            variant="ghost"
            disabled={state.startingTrial}
            onClick={() => onOpenChange(false)}
          >
            Not now
          </Button>
          <Button
            type="button"
            variant="primary"
            loading={state.startingTrial}
            onClick={onStartTrial}
          >
            Start 21-day free trial
          </Button>
        </>
      );
      break;
    case `planUpgradeRequired`:
      title = `Upgrade to connect a Mac`;
      description = `Your current plan doesn't include Gertrude for Mac.`;
      body = <UpgradeRequiredContent />;
      footer = (
        <>
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            Not now
          </Button>
          <Button type="link" href="/settings/billing" variant="primary">
            View plans
          </Button>
        </>
      );
      break;
    case `subscriptionFixRequired`:
      title = `Your subscription is inactive`;
      description = `Update your subscription to continue using Gertrude on Mac computers.`;
      body = null;
      footer = (
        <>
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            Not now
          </Button>
          <Button type="link" href="/settings/billing" variant="primary">
            Manage subscription
          </Button>
        </>
      );
      break;
    case `ready`: {
      const code = formatConnectionCode(state.code);
      title = `Enter this code on the Mac`;
      description = `In the Gertrude welcome screen on ${personName}’s Mac, enter this connection code.`;
      body = (
        <VStack gap={4} className="py-2">
          <div
            role="group"
            aria-label={`Connection code ${code}`}
            className="mx-auto flex items-center justify-center gap-1.5"
          >
            {code.split(``).map((digit, index) => (
              <React.Fragment key={`${digit}-${index}`}>
                {index === 3 && <span aria-hidden="true" className="w-2" />}
                <span
                  aria-hidden="true"
                  className="font-mono text-4xl font-semibold tabular-nums text-stone-950 sm:text-5xl"
                >
                  {digit}
                </span>
              </React.Fragment>
            ))}
          </div>
          <HStack justify="center">
            <Button
              type="button"
              variant="default"
              size="small"
              icon={copied ? CheckIcon : CopyIcon}
              onClick={() => void handleCopy(code)}
            >
              {copied ? `Copied` : `Copy code`}
            </Button>
          </HStack>
          <Text variant="bodyMuted" className="text-center">
            This code works once and expires in two days.
          </Text>
        </VStack>
      );
      footer = (
        <Button type="button" variant="primary" onClick={() => onOpenChange(false)}>
          Done
        </Button>
      );
      break;
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={title}
      description={description}
      showHeader={!promoState}
      bodyPadding={!promoState}
      footer={footer}
      size="medium"
      dismissible={!busy}
    >
      {body}
    </Modal>
  );
};

export default ConnectMacModal;

export function formatConnectionCode(code: number): string {
  return String(code).padStart(6, `0`);
}

const ConnectionInstructions: React.FC<{ personName: string }> = ({ personName }) => (
  <VStack gap={3}>
    <InstructionStep icon={DownloadIcon} title="Install Gertrude">
      On {personName}&rsquo;s Mac, download and open the Gertrude app.
      <div className="mt-3">
        <Button
          type="link"
          href="https://gertrude.app/download"
          target="_blank"
          rel="noreferrer"
          size="small"
          icon={ExternalLinkIcon}
          iconPosition="right"
        >
          Download Gertrude
        </Button>
      </div>
    </InstructionStep>
    <InstructionStep icon={LinkIcon} title="Get a connection code">
      When the welcome screen asks for a code, return here and get one below.
    </InstructionStep>
  </VStack>
);

const TrialRequiredContent: React.FC = () => (
  <PromoCard
    primaryText="Try every Mac feature free for 21 days"
    secondaryText="Connecting Gertrude on a Mac requires the Full plan."
    flush
  />
);

const UpgradeRequiredContent: React.FC = () => (
  <PromoCard
    primaryText="Your free trial has ended"
    secondaryText="Upgrade to the Full plan to continue using Gertrude on Mac computers."
    flush
  />
);
