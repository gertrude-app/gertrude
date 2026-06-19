import { Badge, Button, DropdownMenu, DropdownMenuItem, inflect } from '@gertrude/ui';
import { EllipsisIcon, PencilIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { Keychain, Schedule } from '#/lib/mock';
import ScheduleButton from './ScheduleButton';
import { formatSchedule } from '#/lib/utils';

type Props = Pick<Keychain, `name` | `description` | `numKeys` | `isPublic`> & {
  keychainId: string;
  onRemove: () => void;
  schedule?: Schedule;
  setSchedule: (schedule?: Schedule) => void;
};

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  description,
  numKeys,
  onRemove,
  keychainId,
  schedule,
  setSchedule,
}) => (
  <div className="p-3 flex flex-col bg-white border border-stone-200 rounded-xl shadow shadow-stone-300/30">
    <div className="flex flex-col flex-grow">
      <div className="flex items-center gap-2">
        <span className="text-stone-900 font-medium">{name}</span>
        {isPublic && <Badge size="small">Public</Badge>}
      </div>
      <span className="text-sm text-stone-600">{description}</span>
      {schedule && (
        <span className="text-xs text-stone-800 mt-1 font-medium">
          {formatSchedule(schedule)}
        </span>
      )}
    </div>
    <div className="flex items-center justify-between mt-3 gap-3">
      <span className="text-xs font-medium text-stone-500">
        {numKeys} {inflect(`key`, numKeys)}
      </span>
      <div className="flex gap-2">
        <ScheduleButton schedule={schedule} setSchedule={setSchedule} />
        <DropdownMenu
          trigger={
            <Button type="button" onClick={() => {}} size="small" icon={EllipsisIcon} />
          }
        >
          <DropdownMenuItem
            title={`Edit Keychain`}
            icon={PencilIcon}
            onSelect={() => {
              window.location.href = `/keychains/${keychainId}`;
            }}
          />
          <DropdownMenuItem
            title={`Remove Keychain`}
            icon={TrashIcon}
            onSelect={onRemove}
            destructive
          />
        </DropdownMenu>
      </div>
    </div>
  </div>
);

export default KeychainCard;
