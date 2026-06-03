import React from 'react';
import { Button, Input, Modal, Select, Textarea, inflect } from '@gertrude/ui';
import { ClockIcon } from 'lucide-react';
import type { SuspensionRequest } from '#/lib/mock-data';

interface Props {
  request: SuspensionRequest;
}

type DurationUnit = 'minutes' | 'hours';

const durationUnits: DurationUnit[] = ['minutes', 'hours'];

const parseDuration = (duration: string): { amount: string; unit: DurationUnit } => {
  const [amount = '', unit = 'minutes'] = duration.split(' ');

  return {
    amount,
    unit: unit.startsWith('hour') ? 'hours' : 'minutes',
  };
};

const formatDuration = (amount: number, unit: DurationUnit): string => {
  return `${amount} ${inflect(unit === 'hours' ? 'hour' : 'minute', amount)}`;
};

const SuspensionRequestCard: React.FC<Props> = ({ request }) => {
  const parsedRequestDuration = parseDuration(request.duration);
  const [customDurationOpen, setCustomDurationOpen] = React.useState(false);
  const [customDurationAmount, setCustomDurationAmount] = React.useState(
    parsedRequestDuration.amount,
  );
  const [customDurationUnit, setCustomDurationUnit] = React.useState<DurationUnit>(
    parsedRequestDuration.unit,
  );
  const [denyModalOpen, setDenyModalOpen] = React.useState(false);
  const [denyReason, setDenyReason] = React.useState('');
  const numericCustomDurationAmount = Number(customDurationAmount);
  const canGrantCustomDuration =
    Number.isFinite(numericCustomDurationAmount) && numericCustomDurationAmount > 0;
  const customDurationText = canGrantCustomDuration
    ? formatDuration(numericCustomDurationAmount, customDurationUnit)
    : 'custom duration';

  const handleDenyModalOpenChange = (open: boolean): void => {
    setDenyModalOpen(open);

    if (!open) {
      setDenyReason('');
    }
  };

  return (
    <div className="flex flex-col justify-between rounded-2xl border border-stone-200 bg-white p-4 shadow-md shadow-stone-300/30">
      <div>
        <div className="flex flex-col">
          <h2 className="text-lg font-medium text-stone-900">{request.personName}</h2>
          <span className="text-sm text-stone-600 -mt-0.5">{request.duration}</span>
        </div>
        {request.reason && (
          <p className="w-fit self-start rounded-2xl rounded-tl bg-stone-200 px-3.5 py-2.5 text-sm text-stone-800 mt-2">
            {request.reason}
          </p>
        )}
      </div>
      <div className="flex justify-end gap-2 mt-4">
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
          onClick={() => {}}
          size="small"
          dropdownAriaLabel="Grant with another duration"
          dropdownItems={[
            { title: 'Grant 5 minutes', icon: ClockIcon, onSelect: () => {} },
            { title: 'Grant 30 minutes', icon: ClockIcon, onSelect: () => {} },
            { title: 'Grant 1 hour', icon: ClockIcon, onSelect: () => {} },
            {
              title: 'Custom duration…',
              icon: ClockIcon,
              onSelect: () => setCustomDurationOpen(true),
            },
          ]}
        >
          Grant {request.duration}
        </Button>
      </div>
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
            <Button
              type="button"
              onClick={() => handleDenyModalOpenChange(false)}
              variant="destructive"
            >
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
              onClick={() => setCustomDurationOpen(false)}
              variant="primary"
              disabled={!canGrantCustomDuration}
            >
              Grant {customDurationText}
            </Button>
          </>
        }
      >
        <div className="grid gap-4 sm:grid-cols-[1fr_10rem]">
          <Input
            type="number"
            label="Duration"
            value={customDurationAmount}
            setValue={setCustomDurationAmount}
          />
          <Select
            label="Unit"
            selected={customDurationUnit}
            setSelected={(unit) => setCustomDurationUnit(unit as DurationUnit)}
            possibleValues={durationUnits}
          />
        </div>
      </Modal>
    </div>
  );
};

export default SuspensionRequestCard;
