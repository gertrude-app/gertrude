import { Button, HStack, Tooltip } from '@gertrude/ui';
import { FlagIcon, TrashIcon } from 'lucide-react';
import React from 'react';

interface Props {
  id: string;
  flagged: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
}

const ActivityItemActions: React.FC<Props> = ({
  id,
  flagged,
  onToggleFlag,
  onDelete,
}) => {
  if (!onToggleFlag && !onDelete) {
    return null;
  }

  return (
    <HStack gap={2} className="relative">
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
      <Button
        type="button"
        onClick={() => onDelete?.(id)}
        icon={TrashIcon}
        disabled={flagged}
      >
        Delete
      </Button>
    </HStack>
  );
};

export default ActivityItemActions;
