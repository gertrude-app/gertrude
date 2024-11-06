import React from 'react';
import cx from 'classnames';
import { inflect } from '@shared/string';
import { Button, Badge } from '@shared/components';
import { ChevronDownIcon, ClockIcon, TrashIcon } from '@heroicons/react/24/outline';
import { UsersIcon } from '@heroicons/react/24/solid';
import { defaults, type KeychainSchedule as Schedule } from '@dash/types';
import GradientIcon from '../GradientIcon';
import KeychainSchedule from './schedule/KeychainSchedule';

type Props =
  | ({
      mode: 'keychains_screen';
      id: UUID;
      onRemove(): unknown;
    } & Common)
  | ({
      mode: 'assign_to_child';
      onRemove(): unknown;
      schedule?: Schedule;
      setSchedule(schedule?: Schedule): unknown;
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
  const [showSchedule, setShowSchedule] = React.useState(false);
  return (
    <div
      className={cx(
        `rounded-2xl shadow-md shadow-slate-300/40 border-[0.5px] border-slate-200 flex flex-col justify-between transition-[background-color,border-color] duration-100`,
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
                <Badge size="small" type="green">
                  Public
                </Badge>
              )}
            </div>
          </div>
          {isSelect(props) || (
            <p
              className={cx(
                description ? `text-slate-500 leading-tight` : `text-slate-400/70 italic`,
                `mt-1.5 mb-1 text-sm`,
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
            `w-full flex flex-col py-2 border-t border-slate-100`,
            isSelect(props) && props.selected && `bg-indigo-100/40`,
          )}
        >
          <div className="flex justify-between">
            <Badge
              type="green"
              size="medium"
              className={cx(`ml-3 self-center`, !isPublic && `opacity-0`)}
            >
              <UsersIcon className="w-3.5 h-3.5 mr-2 text-green-600 hidden min-[400px]:block" />
              {` `}
              Public
            </Badge>
            {props.mode !== `select` && (
              <div className="flex items-center pr-2 gap-2">
                {props.mode === `assign_to_child` && !props.schedule && (
                  <button
                    onClick={() => {
                      props.setSchedule(defaults.keychainSchedule());
                      setShowSchedule(true);
                    }}
                    className={cx(
                      `flex items-center px-2 py-1 rounded-full transition-[background-color,transform] duration-200 active:scale-90 gap-1.5 bg-slate-200/50 hover:bg-slate-200 active:bg-slate-300`,
                    )}
                  >
                    <ClockIcon
                      className={cx(`w-3.5 h-3.5 shrink-0 text-slate-500`)}
                      strokeWidth={2.5}
                    />
                    <span className="text-sm text-slate-600 font-medium">
                      Add schedule
                    </span>
                  </button>
                )}
                {props.mode === `assign_to_child` && props.schedule && (
                  <button
                    onClick={() => setShowSchedule(!showSchedule)}
                    className={cx(
                      `flex items-center px-2 py-1 rounded-lg transition-[background-color,transform] duration-200 active:scale-90`,
                      showSchedule
                        ? `bg-violet-100 hover:bg-violet-200 active:bg-violet-300`
                        : `hover:bg-slate-200 active:bg-slate-300`,
                    )}
                  >
                    <ClockIcon
                      className={cx(
                        `w-4 h-4 shrink-0`,
                        showSchedule ? `text-violet-500` : `text-slate-500`,
                      )}
                      strokeWidth={2.5}
                    />
                    <ChevronDownIcon
                      className={cx(
                        `w-3 h-3 shrink-0 transition-transform duration-200`,
                        showSchedule ? `-rotate-180 text-violet-400` : `text-slate-400`,
                      )}
                      strokeWidth={2.5}
                    />
                  </button>
                )}
                {props.mode === `keychains_screen` && (
                  <Button
                    type="link"
                    color="tertiary"
                    size="small"
                    to={`/keychains/${props.id}`}
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
                  {props.mode === `keychains_screen` ? `Delete` : `Remove`}
                </Button>
              </div>
            )}
          </div>
          {props.mode === `assign_to_child` && props.schedule && (
            <div
              className={cx(
                `flex justify-center items-center gap-2 transition-[height,filter,opacity,margin] duration-300 px-4`,
                showSchedule ? ` mt-2` : `h-0 opacity-0 blur-lg pointer-events-none mt-0`,
              )}
            >
              <ClockIcon className="w-4 text-slate-400 shrink-0" strokeWidth={2.5} />
              <KeychainSchedule
                schedule={props.schedule}
                setSchedule={props.setSchedule}
              />
              <button
                onClick={() => {
                  props.setSchedule(undefined);
                  setShowSchedule(false);
                }}
                className="h-5 w-5 flex justify-center items-center rounded-full hover:scale-150 hover:bg-slate-100 transition-[transform,background-color] duration-200 group active:scale-100 active:bg-slate-300"
              >
                <TrashIcon
                  title="Remove schedule from keychain"
                  strokeWidth={2}
                  className="w-4 h-4 text-red-500 group-hover:scale-75 transition-transform duration-200"
                />
              </button>
            </div>
          )}
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
