import React from 'react';
import cx from 'classnames';
import { inflect } from '@shared/string';
import { Button, PillBadge } from '@shared/components';
import type { Schedule } from './schedule/KeychainSchedule';
import GradientIcon from '../GradientIcon';
import KeychainSchedule from './schedule/KeychainSchedule';

type Props =
  | ({
      mode: 'list';
      onRemove(): unknown;
      removeText: string;
      editUrl?: string;
      schedule?: Schedule;
    } & Common)
  | ({
      mode: 'select';
      selected: boolean;
      onSelect(): unknown;
    } & Common);

type Common = {
  name: string;
  description?: string;
  numKeys: number;
  isPublic: boolean;
};

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  numKeys,
  description,
  ...props
}) => {
  const [schedule, setSchedule] = React.useState<Schedule | null>(
    props.mode === `list` ? props.schedule || null : null,
  );

  return (
    <div
      className={cx(
        `rounded-2xl shadow-lg shadow-slate-300/50 border-[0.5px] border-slate-200 flex flex-col justify-between transition-[background-color,border-color] duration-100`,
        isSelect(props) && props.selected ? `bg-violet-50 border-violet-300` : `bg-white`,
        isSelect(props) && !props.selected && `hover:bg-slate-50 cursor-pointer`,
        isSelect(props) && `min-h-[77px]`,
      )}
      onClick={isSelect(props) ? props.onSelect : undefined}
      data-test="keychain-card"
    >
      <div className="flex items-stretch flex-grow">
        <div
          className={cx(
            `w-16 xs:w-20 shrink-0 py-4 flex justify-center mr-2`,
            isSelect(props) && `items-center`,
          )}
        >
          <GradientIcon icon="list" size="medium" className="mx-0" />
        </div>
        <div
          className={cx(
            `pr-4 py-4 flex flex-col flex-grow`,
            isSelect(props) ? `justify-center` : `justify-start`,
          )}
        >
          <div className="flex flex-col md:flex-row justify-between md:items-center relative right-0">
            <h2 className="text-left font-semibold text-lg leading-6 text-slate-900 sm:whitespace-normal">
              {name}
            </h2>
            <div className="flex md:justify-end pt-1 md:pt-0 items-center shrink-0 space-x-2 flex-grow">
              <h4 className="text-slate-500 shrink-0">
                {numKeys}
                {` `}
                {inflect(`key`, numKeys)}
              </h4>
              {isSelect(props) && isPublic && (
                <PillBadge size="small" type="green">
                  Public
                </PillBadge>
              )}
            </div>
          </div>
          {isSelect(props) || (
            <p
              className={cx(
                description ? `text-slate-600 leading-tight` : `text-slate-400 italic`,
                `mt-1.5 mb-1`,
              )}
            >
              {description || `No description`}
            </p>
          )}
        </div>
      </div>
      {isSelect(props) || (
        <div
          className={cx(
            `bg-slate-50 rounded-b-2xl w-full flex flex-col py-2`,
            isSelect(props) && props.selected && `bg-indigo-100/40`,
          )}
        >
          <div className="flex justify-between">
            <PillBadge
              type="green"
              size="large"
              className={cx(`border ml-3`, !isPublic && `opacity-0`)}
            >
              <i className="fa-solid fa-users mr-2 text-sm" /> Public
            </PillBadge>
            {props.mode === `list` && (
              <div className="flex items-center pr-2 space-x-2">
                {props.editUrl && (
                  <Button
                    type="link"
                    color="tertiary"
                    size="small"
                    to={props.editUrl}
                    testId="edit-keychain"
                  >
                    Edit
                  </Button>
                )}
                <Button
                  type="button"
                  onClick={props.onRemove}
                  color="warning"
                  testId="remove-keychain"
                  size="small"
                >
                  {props.removeText}
                </Button>
              </div>
            )}
          </div>
          {schedule && <KeychainSchedule schedule={schedule} setSchedule={setSchedule} />}
        </div>
      )}
    </div>
  );
};

export default KeychainCard;

function isSelect(props: { mode: Props['mode'] }): props is {
  mode: 'select';
} & Common {
  return props.mode === `select`;
}
