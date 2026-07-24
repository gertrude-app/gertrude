import {
  Button,
  Input,
  Modal,
  Select,
  Stack,
  Text,
  Textarea,
  VStack,
} from '@gertrude/ui';
import { time } from '@shared/datetime';
import React from 'react';
import type { SuspensionRequest } from '#/components/types';
import RequestReasonBubble from './RequestReasonBubble';

interface Props {
  request: SuspensionRequest;
  open: boolean;
  responding?: `deny` | `grant`;
  onOpenChange: (open: boolean) => void;
  onDeny: (comment: string) => Promise<void>;
  onGrant: (
    durationInSeconds: number,
    extraMonitoring: string | undefined,
    comment: string,
  ) => Promise<void>;
}

type DurationUnit = `minutes` | `hours`;

const durationUnits: DurationUnit[] = [`minutes`, `hours`];

const durationOptions = [
  { value: `180`, label: `3 minutes` },
  { value: `300`, label: `5 minutes` },
  { value: `600`, label: `10 minutes` },
  { value: `1200`, label: `20 minutes` },
  { value: `1800`, label: `30 minutes` },
  { value: `3600`, label: `1 hour` },
  { value: `5400`, label: `1.5 hours` },
  { value: `7200`, label: `2 hours` },
  { value: `custom`, label: `Custom duration…` },
];

export const sortExtraMonitoringOptions = (a: string, b: string): number => {
  if (a === b) return 0;
  if (b === `k`) return a.includes(`k`) ? 1 : -1;
  if (a === `k`) return b.includes(`k`) ? -1 : 1;
  if (a.includes(`k`) && !b.includes(`k`)) return 1;
  if (b.includes(`k`) && !a.includes(`k`)) return -1;

  const matchA = a.match(/@(\d+)/);
  const matchB = b.match(/@(\d+)/);
  if (matchA && matchB) {
    const numA = Number(matchA[1]);
    const numB = Number(matchB[1]);
    return numA === numB ? 0 : numA > numB ? -1 : 1;
  }

  return a < b ? -1 : 1;
};

const SuspensionRequestResponseModal: React.FC<Props> = ({
  request,
  open,
  responding,
  onOpenChange,
  onDeny,
  onGrant,
}) => {
  const requestedDuration = String(request.requestedDurationInSeconds);
  const requestedDurationIsPreset = durationOptions.some(
    (option) => option.value === requestedDuration,
  );
  const [selectedDuration, setSelectedDuration] = React.useState(
    requestedDurationIsPreset ? requestedDuration : `custom`,
  );
  const initialCustomDurationUnit: DurationUnit =
    request.requestedDurationInSeconds % 3600 === 0 ? `hours` : `minutes`;
  const [customDurationAmount, setCustomDurationAmount] = React.useState(
    String(
      request.requestedDurationInSeconds /
        (initialCustomDurationUnit === `hours` ? 3600 : 60),
    ),
  );
  const [customDurationUnit, setCustomDurationUnit] = React.useState<DurationUnit>(
    initialCustomDurationUnit,
  );
  const [comment, setComment] = React.useState(``);
  const extraMonitoringOptions = React.useMemo(
    () =>
      Object.entries(request.extraMonitoringOptions)
        .sort(([a], [b]) => sortExtraMonitoringOptions(a, b))
        .map(([value, label]) => ({ value, label })),
    [request.extraMonitoringOptions],
  );
  const monitoringStorageKey = `extra_monitoring:${request.personId}`;
  const [selectedExtraMonitoring, setSelectedExtraMonitoring] = React.useState(() => {
    const stored = localStorage.getItem(monitoringStorageKey);
    return stored && request.extraMonitoringOptions[stored] ? stored : `off`;
  });
  const numericCustomDuration = Number(customDurationAmount);
  const canGrantCustomDuration =
    Number.isFinite(numericCustomDuration) && numericCustomDuration > 0;
  const durationInSeconds =
    selectedDuration === `custom`
      ? Math.round(numericCustomDuration * (customDurationUnit === `hours` ? 3600 : 60))
      : Number(selectedDuration);
  const canGrant = selectedDuration !== `custom` || canGrantCustomDuration;
  const grantedDuration = canGrant
    ? time.humanDuration(durationInSeconds)
    : `custom duration`;
  const isResponding = responding !== undefined;

  const handleExtraMonitoringChange = (value: string): void => {
    setSelectedExtraMonitoring(value);
    if (value === `off`) {
      localStorage.removeItem(monitoringStorageKey);
    } else {
      localStorage.setItem(monitoringStorageKey, value);
    }
  };

  const handleDeny = (): void => {
    void onDeny(comment.trim()).catch(() => undefined);
  };

  const handleGrant = (): void => {
    void onGrant(
      durationInSeconds,
      selectedExtraMonitoring === `off` ? undefined : selectedExtraMonitoring,
      comment.trim(),
    ).catch(() => undefined);
  };

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={`Respond to ${request.personName}'s request`}
      description={`${request.personName} asked to pause filtering for ${request.duration}${request.deviceName ? ` on ${request.deviceName}` : ``}.`}
      size="medium"
      dismissible={!isResponding}
      footer={
        <>
          <Button
            type="button"
            onClick={() => onOpenChange(false)}
            variant="ghost"
            disabled={isResponding}
          >
            Cancel
          </Button>
          <Button
            type="button"
            onClick={handleDeny}
            variant="destructive"
            loading={responding === `deny`}
            disabled={isResponding}
          >
            Deny
          </Button>
          <Button
            type="button"
            onClick={handleGrant}
            variant="primary"
            loading={responding === `grant`}
            disabled={!canGrant || isResponding}
          >
            Grant {grantedDuration}
          </Button>
        </>
      }
    >
      <VStack gap={4}>
        {request.reason && <RequestReasonBubble>{request.reason}</RequestReasonBubble>}
        <VStack gap={3}>
          <Select
            label="Duration"
            selected={selectedDuration}
            setSelected={setSelectedDuration}
            possibleValues={durationOptions}
            disabled={isResponding}
          />
          {selectedDuration === `custom` && (
            <Stack direction={{ default: `vertical`, sm: `horizontal` }} gap={4}>
              <Input
                type="number"
                label="Custom duration"
                value={customDurationAmount}
                setValue={setCustomDurationAmount}
                className="sm:flex-1"
                disabled={isResponding}
              />
              <Select
                label="Unit"
                selected={customDurationUnit}
                setSelected={setCustomDurationUnit}
                possibleValues={durationUnits}
                className="sm:w-40"
                disabled={isResponding}
              />
            </Stack>
          )}
        </VStack>
        {extraMonitoringOptions.length > 0 && (
          <VStack gap={1.5}>
            <Select
              label="Monitoring during suspension"
              selected={selectedExtraMonitoring}
              setSelected={handleExtraMonitoringChange}
              possibleValues={[
                { value: `off`, label: `No extra monitoring` },
                ...extraMonitoringOptions,
              ]}
              disabled={isResponding}
            />
            <Text variant="proseSubtle" className="px-2.5">
              Temporarily add monitoring while filtering is paused. Normal settings return
              when the suspension ends.
            </Text>
          </VStack>
        )}
        <Textarea
          value={comment}
          setValue={setComment}
          label={`Comment to ${request.personName} (optional)`}
          placeholder="Add a reason or note for this response..."
          rows={3}
          resize="vertical"
          disabled={isResponding}
        />
      </VStack>
    </Modal>
  );
};

export default SuspensionRequestResponseModal;
