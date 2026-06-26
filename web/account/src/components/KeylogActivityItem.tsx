import { Button, Tooltip } from '@gertrude/ui';
import { FlagIcon, TrashIcon } from 'lucide-react';
import React from 'react';

interface Props {
  id: string;
  text: string;
  applicationName: string;
  date: Date;
  flagged: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
}

const KeylogActivityItem: React.FC<Props> = ({
  id,
  text,
  applicationName,
  flagged,
  onToggleFlag,
  onDelete,
}) => (
  <div className="border border-stone-200 bg-white rounded-xl shadow shadow-stone-300/30 flex flex-col overflow-hidden">
    <p className="text-sm @lg/main:text-base font-mono text-stone-800 p-3 bg-stone-50 border-b border-stone-200 flex flex-col">
      {text.split(`\n`).map((line) => (
        <span>{line}</span>
      ))}
    </p>
    <div className="p-3 flex items-center justify-between gap-2">
      <span className="text-stone-600 text-xs @lg/main:text-sm">
        Typed in <span className="font-medium text-stone-900">{applicationName}</span>
      </span>
      {(onToggleFlag || onDelete) && (
        <div className="flex items-center gap-2 relative">
          {flagged && (
            <div className="absolute w-120 h-40 rounded-[100%] -left-40 -bottom-24 [background:radial-gradient(#ddbb5535,transparent_70%)]" />
          )}
          <Tooltip
            content={
              flagged
                ? `Flagged items won't be deleted for 60 days`
                : `Flag to prevent deletion for 60 days`
            }
          >
            <Button
              type="button"
              onClick={() => onToggleFlag?.(id)}
              icon={FlagIcon}
              fillIcon={flagged}
              variant={flagged ? `selected` : `ghost`}
            >
              {flagged ? `Flagged` : `Flag`}
            </Button>
          </Tooltip>
          <Button type="button" onClick={() => onDelete?.(id)} icon={TrashIcon}>
            Delete
          </Button>
        </div>
      )}
    </div>
  </div>
);

export default KeylogActivityItem;
