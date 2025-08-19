import { PlusIcon } from '@heroicons/react/24/solid';
import { Button } from '@shared/components';
import React from 'react';
import type { EditBlockRuleProps } from '@dash/block-rules';
import EmptyState from '../EmptyState';
import { TrashBtn } from '../Forms';
import BlockRuleSummary from './BlockRuleSummary';

export type Props = {
  rules: Array<[UUID, EditBlockRuleProps]>;
  onDelete(id: UUID): unknown;
  onEdit(id: UUID): unknown;
  onAdd(): unknown;
  className?: string;
};

const EditBlockRules: React.FC<Props> = ({
  rules,
  className,
  onAdd,
  onEdit,
  onDelete,
}) => (
  <div className={`flex flex-col gap-4 ${className ?? ``}`}>
    {rules.length === 0 ? (
      <EmptyState
        heading="No block rules"
        secondaryText="Let's make some"
        icon="globe"
        buttonText="Add block rule"
        action={onAdd}
      />
    ) : (
      <>
        <div className="flex flex-col gap-1 cursor-pointer">
          {rules.map(([id, rule], idx) => (
            <div
              key={idx}
              className="flex items-center justify-between gap-2 px-2 py-1 rounded-lg group transition hover:bg-slate-50"
              onClick={() => onEdit(id)}
            >
              <BlockRuleSummary {...rule} />
              <TrashBtn onClick={() => onDelete(id)} />
            </div>
          ))}
        </div>
        <div className="flex items-center justify-end mt-2">
          <Button
            type="button"
            onClick={onAdd}
            color="secondary"
            className="flex justify-center"
          >
            <PlusIcon className="w-5 h-5 mr-2" />
            Add rule
          </Button>
        </div>
      </>
    )}
  </div>
);

export default EditBlockRules;
