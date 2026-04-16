import { PlusIcon } from '@heroicons/react/24/solid';
import { Button } from '@shared/components';
import React from 'react';
import type { EditBlockRuleProps } from '@dash/block-rules';
import EmptyState from '../EmptyState';
import { TrashBtn } from '../Forms';
import BlockRuleSummary from './BlockRuleSummary';

export type Rule = {
  id: UUID;
  props: EditBlockRuleProps;
  readOnly?: boolean;
};

export type Props = {
  rules: Array<Rule>;
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
        <div className="flex flex-col gap-1">
          {rules.map(({ id, props, readOnly }, idx) => (
            <div
              key={idx}
              className={`flex items-center justify-between gap-2 px-2 py-1 rounded-lg group transition ${
                readOnly ? `` : `cursor-pointer hover:bg-slate-50`
              }`}
              onClick={readOnly ? undefined : () => onEdit(id)}
            >
              <BlockRuleSummary {...props} />
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
