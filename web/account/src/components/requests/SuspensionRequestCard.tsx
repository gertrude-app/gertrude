import {
  Button,
  Card,
  HStack,
  Input,
  Modal,
  Select,
  Stack,
  Text,
  Textarea,
  VStack,
  inflect,
} from '@gertrude/ui';
import { ClockIcon } from 'lucide-react';
import React from 'react';
import type { SuspensionRequest } from '#/components/types';
import RequestReasonBubble from './RequestReasonBubble';

interface Props {
  request: SuspensionRequest;
  onDeny: (id: string, reason: string) => void;
  onGrant: (id: string, duration: string) => void;
}

type DurationUnit = `minutes` | `hours`;

const durationUnits: DurationUnit[] = [`minutes`, `hours`];

const parseDuration = (duration: string): { amount: string; unit: DurationUnit } => {
  const [amount = ``, unit = `minutes`] = duration.split(` `);

  return {
    amount,
    unit: unit.startsWith(`hour`) ? `hours` : `minutes`,
  };
};

const formatDuration = (amount: number, unit: DurationUnit): string =>
  `${amount} ${inflect(unit === `hours` ? `hour` : `minute`, amount)}`;

const SuspensionRequestCard: React.FC<Props> = ({ request, onDeny, onGrant }) => {
  const parsedRequestDuration = parseDuration(request.duration);
  const [customDurationOpen, setCustomDurationOpen] = React.useState(false);
  const [customDurationAmount, setCustomDurationAmount] = React.useState(
    parsedRequestDuration.amount,
  );
  const [customDurationUnit, setCustomDurationUnit] = React.useState<DurationUnit>(
    parsedRequestDuration.unit,
  );
  const [denyModalOpen, setDenyModalOpen] = React.useState(false);
  const [denyReason, setDenyReason] = React.useState(``);
  const numericCustomDurationAmount = Number(customDurationAmount);
  const canGrantCustomDuration =
    Number.isFinite(numericCustomDurationAmount) && numericCustomDurationAmount > 0;
  const customDurationText = canGrantCustomDuration
    ? formatDuration(numericCustomDurationAmount, customDurationUnit)
    : `custom duration`;

  const handleDenyModalOpenChange = (open: boolean): void => {
    setDenyModalOpen(open);

    if (!open) {
      setDenyReason(``);
    }
  };

  const handleDenyRequest = (): void => {
    onDeny(request.id, denyReason);
    handleDenyModalOpenChange(false);
  };

  const handleGrantRequest = (duration: string): void => {
    onGrant(request.id, duration);
  };

  const handleGrantCustomDuration = (): void => {
    setCustomDurationOpen(false);
    handleGrantRequest(customDurationText);
  };

  return (
    <Card preset="big" padding={4} className="flex flex-col justify-between">
      <VStack>
        <VStack>
          <Text as="h2" variant="heading">
            {request.personName}
          </Text>
          <Text variant="bodySubtle" className="-mt-0.5">
            {request.duration}
          </Text>
        </VStack>
        {request.reason && (
          <RequestReasonBubble className="mt-2">{request.reason}</RequestReasonBubble>
        )}
      </VStack>
      <HStack justify="end" gap={2} className="mt-4">
        <Button
          type="button"
          onClick={() => setDenyModalOpen(true)}
          variant="ghost"
          size="small"
        >
          Deny
        </Button>
        <Button
          type="button"
          onClick={() => handleGrantRequest(request.duration)}
          size="small"
          dropdownAriaLabel="Grant with another duration"
          dropdownItems={[
            {
              title: `Grant 5 minutes`,
              icon: ClockIcon,
              onSelect: () => handleGrantRequest(`5 minutes`),
            },
            {
              title: `Grant 30 minutes`,
              icon: ClockIcon,
              onSelect: () => handleGrantRequest(`30 minutes`),
            },
            {
              title: `Grant 1 hour`,
              icon: ClockIcon,
              onSelect: () => handleGrantRequest(`1 hour`),
            },
            {
              title: `Custom duration…`,
              icon: ClockIcon,
              onSelect: () => setCustomDurationOpen(true),
            },
          ]}
        >
          Grant {request.duration}
        </Button>
      </HStack>
      <Modal
        open={denyModalOpen}
        onOpenChange={handleDenyModalOpenChange}
        title="Deny suspension request?"
        description={`${request.personName} will be told that this suspension request was denied.`}
        size="small"
        footer={
          <>
            <Button
              type="button"
              onClick={() => handleDenyModalOpenChange(false)}
              variant="ghost"
            >
              Cancel
            </Button>
            <Button type="button" onClick={handleDenyRequest} variant="destructive">
              Deny request
            </Button>
          </>
        }
      >
        <Textarea
          value={denyReason}
          setValue={setDenyReason}
          label="Optional comment"
          placeholder="Add a reason or note for this denial..."
          rows={4}
          resize="vertical"
        />
      </Modal>
      <Modal
        open={customDurationOpen}
        onOpenChange={setCustomDurationOpen}
        title="Grant custom duration"
        description={`${request.personName} requested ${request.duration}.`}
        footer={
          <>
            <Button
              type="button"
              onClick={() => setCustomDurationOpen(false)}
              variant="ghost"
            >
              Cancel
            </Button>
            <Button
              type="button"
              onClick={handleGrantCustomDuration}
              variant="primary"
              disabled={!canGrantCustomDuration}
            >
              Grant {customDurationText}
            </Button>
          </>
        }
      >
        <Stack direction={{ default: `vertical`, sm: `horizontal` }} gap={4}>
          <Input
            type="number"
            label="Duration"
            value={customDurationAmount}
            setValue={setCustomDurationAmount}
          />
          <Select
            label="Unit"
            selected={customDurationUnit}
            setSelected={setCustomDurationUnit}
            possibleValues={durationUnits}
            className="sm:w-40"
          />
        </Stack>
      </Modal>
    </Card>
  );
};

export default SuspensionRequestCard;
