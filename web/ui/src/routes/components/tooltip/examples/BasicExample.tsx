import { InfoIcon, LockIcon, Trash2Icon } from 'lucide-react';
import React from 'react';
import Button from '#/components/ui/Button';
import Tooltip, { TooltipProvider } from '#/components/ui/Tooltip';

const BasicExample: React.FC = () => (
  <div className="flex h-full items-center justify-center p-8">
    <TooltipProvider>
      <div className="flex flex-wrap items-center justify-center gap-3">
        <Tooltip content="Private rules are visible only to admins.">
          <Button
            type="button"
            onClick={() => undefined}
            icon={LockIcon}
            ariaLabel="Private rules"
          />
        </Tooltip>
        <Tooltip content="Deletes this item after confirmation." side="bottom">
          <Button
            type="button"
            onClick={() => undefined}
            icon={Trash2Icon}
            ariaLabel="Delete item"
          />
        </Tooltip>
        <Tooltip content="Tooltip content should clarify, not carry essential information.">
          <Button
            type="button"
            onClick={() => undefined}
            icon={InfoIcon}
            ariaLabel="Tooltip guidance"
          />
        </Tooltip>
        <Tooltip content="Button triggers work too.">
          <Button type="button" onClick={() => undefined}>
            Hover or focus me
          </Button>
        </Tooltip>
      </div>
    </TooltipProvider>
  </div>
);

export default BasicExample;
