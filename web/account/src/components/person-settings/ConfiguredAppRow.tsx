import { Button, DropdownMenu, DropdownMenuItem } from '@gertrude/ui';
import { EllipsisIcon, TrashIcon, XIcon } from 'lucide-react';
import React from 'react';
import type { ConfiguredMacApp, Schedule } from '#/components/types';
import ScheduleButton, { ScheduleEditor } from './ScheduleButton';
import { formatSchedule } from '#/components/utils';

interface Props {
  app: ConfiguredMacApp;
  onRemove: () => void;
  setSchedule?: (schedule?: Schedule) => void;
}

const ConfiguredAppRow: React.FC<Props> = ({ app, onRemove, setSchedule }) => (
  <div className="flex items-center justify-between border gap-2 p-3 rounded-xl border-stone-200 shadow shadow-stone-300/30 bg-white">
    <div className="flex items-center gap-3">
      <div className="shrink-0">
        <img
          src={app.appIconUrl}
          alt=""
          className="w-10 h-10 absolute blur-xs opacity-50"
        />
        <img
          src={app.appIconUrl}
          alt=""
          className="w-10 h-10 shadow rounded-[11px] relative"
        />
      </div>
      <div className="flex flex-col">
        <span className="font-medium text-stone-800">{app.nameOrBundleId}</span>
        {app.schedule && (
          <span className="text-xs text-stone-600 -mt-0.25">
            {formatSchedule(app.schedule)}
          </span>
        )}
      </div>
    </div>
    {setSchedule ? (
      <>
        <div className="hidden items-center gap-2 sm:flex">
          <ScheduleButton schedule={app.schedule} setSchedule={setSchedule} />
          <Button
            type="button"
            ariaLabel={`Remove ${app.nameOrBundleId}`}
            onClick={onRemove}
            icon={XIcon}
            size="small"
            variant="ghost"
          />
        </div>
        <div className="sm:hidden">
          <DropdownMenu
            contentClassName="w-82"
            trigger={
              <Button
                type="button"
                ariaLabel={`More actions for ${app.nameOrBundleId}`}
                onClick={() => {}}
                icon={EllipsisIcon}
                size="small"
              />
            }
          >
            <ScheduleEditor schedule={app.schedule} setSchedule={setSchedule} />
            <div className="mx-1 border-t border-stone-200 pt-1">
              <DropdownMenuItem
                title="Remove App"
                icon={TrashIcon}
                onSelect={onRemove}
                destructive
              />
            </div>
          </DropdownMenu>
        </div>
      </>
    ) : (
      <Button
        type="button"
        ariaLabel={`Remove ${app.nameOrBundleId}`}
        onClick={onRemove}
        icon={XIcon}
        size="small"
        variant="ghost"
      />
    )}
  </div>
);

export default ConfiguredAppRow;
