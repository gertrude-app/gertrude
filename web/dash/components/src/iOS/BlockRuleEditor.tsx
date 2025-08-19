import { SelectMenu, TextInput } from '@shared/components';
import React from 'react';
import type { BlockCondition, EditBlockRuleProps, EditEvent } from '@dash/block-rules';
import { BlockOption } from '../Forms';

type Props = EditBlockRuleProps & {
  emit: (event: EditEvent) => unknown;
};

const BlockRuleEditor: React.FC<Props> = ({
  type,
  primaryValue,
  secondaryValue,
  condition,
  emit,
}) => (
  <div className="flex flex-col gap-6">
    <div className="flex flex-col gap-4 sm:flex-row">
      <BlockOption
        icon="phone"
        selected={type === `app`}
        onClick={() => emit({ type: `setType`, value: `app` })}
        title="Block app"
        description="Block a specific iOS app"
        className="sm:w-1/2 sm:ml-2"
      />
      <BlockOption
        icon="globe"
        selected={type === `address`}
        onClick={() => emit({ type: `setType`, value: `address` })}
        title="Block address"
        description="Block an internet address"
        className="sm:w-1/2 sm:mr-2 mb-3 sm:mb-0"
      />
    </div>
    <div className="flex flex-col gap-2">
      <TextInput
        type="text"
        label={type === `app` ? `App Bundle ID:` : `When address contains:`}
        placeholder={type === `app` ? `e.g. com.acme.app` : `e.g. example.com`}
        value={primaryValue}
        setValue={(value) => emit({ type: `setPrimaryValue`, value })}
        className="w-full"
      />
    </div>
    <div className="flex gap-2 items-center justify-end">
      <label className="text-slate-700 dark:text-slate-300">
        {type === `app` ? `Block internet access:` : `Block address`}
      </label>
      <SelectMenu
        size="medium"
        options={getConditionOpts(type)}
        selectedOption={condition}
        setSelected={(value) => emit({ type: `setCondition`, value })}
      />
    </div>
    {(condition === `unlessAddressContains` || condition === `whenAddressContains`) && (
      <div className="flex flex-col gap-2 bg-violet-50 border border-violet-100 rounded-xl p-4">
        <TextInput
          type={condition === `unlessAddressContains` ? `textarea` : `text`}
          rows={3}
          value={secondaryValue}
          setValue={(value) => emit({ type: `setSecondaryValue`, value })}
          placeholder={
            condition === `unlessAddressContains` ? `foo.com\nbar.com` : `bad-site.com`
          }
          className="w-full"
        />
        {condition === `unlessAddressContains` && (
          <span className="text-xs text-slate-500 mt-1">Enter one address per line.</span>
        )}
      </div>
    )}
  </div>
);

export default BlockRuleEditor;

function getConditionOpts(
  type: `app` | `address`,
): Array<{ value: BlockCondition; display: string }> {
  if (type === `app`) {
    return [
      { value: `always`, display: `completely` },
      { value: `whenAddressContains`, display: `when address contains...` },
      { value: `unlessAddressContains`, display: `unless address contains...` },
      { value: `whenIsBrowser`, display: `when is browser` },
    ];
  }
  return [
    { value: `always`, display: `always` },
    { value: `whenIsBrowser`, display: `when is browser` },
  ];
}
