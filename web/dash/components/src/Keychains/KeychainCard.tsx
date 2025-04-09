import React, { useEffect, useRef, useState } from 'react';
import cx from 'classnames';
import { inflect } from '@shared/string';
import { Button, Badge } from '@shared/components';
import { ChevronDownIcon, ClockIcon, TrashIcon } from '@heroicons/react/24/outline';
import { UsersIcon } from '@heroicons/react/24/solid';
import { defaults, type RuleSchedule as Schedule } from '@dash/types';
import { Link } from 'react-router-dom';
import GradientIcon from '../GradientIcon';
import SchedulePicker from './schedule/SchedulePicker';

type Props =
  | ({
      mode: 'keychains_screen';
      id: UUID;
      assignedChildren: UUID[];
      allChildren: Array<{
        name: string;
        id: UUID;
      }>;
      onRemove(): unknown;
      toggleChild(userId: string): void;
    } & Common)
  | ({
      mode: 'assigned_to_child';
      keychainId: UUID;
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
  const [showSchedule, setShowSchedule] = useState(false);
  const [assignToChildExpanded, setAssignToChildExpanded] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent): void {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setAssignToChildExpanded(false);
      }
    }

    document.addEventListener(`mousedown`, handleClickOutside);
    return () => {
      document.removeEventListener(`mousedown`, handleClickOutside);
    };
  }, [dropdownRef]);

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
          <div className="flex flex-col md:flex-row justify-between md:items-start relative right-0">
            <div>
              <h2 className="text-left font-semibold text-lg leading-6 text-slate-900 sm:whitespace-normal">
                {name}
              </h2>
              {props.mode === `keychains_screen` &&
                props.assignedChildren.length === 0 && (
                  <h3 className="text-sm text-red-700 font-medium">
                    This keychain isn't doing anything
                  </h3>
                )}
            </div>
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
            <div className="flex flex-col gap-3">
              <p
                className={cx(
                  description
                    ? `text-slate-500 leading-tight`
                    : `text-slate-400/70 italic`,
                  `mt-1.5 mb-1 text-sm`,
                )}
              >
                {description || `No description`}
              </p>
              {props.mode === `keychains_screen` && (
                <div className="flex flex-wrap items-center gap-y-2">
                  {props.allChildren.map((child) => (
                    <Link
                      key={child.id}
                      to={`/children/${child.id}`}
                      className={cx(
                        `bg-violet-100 text-violet-700 text-sm font-medium rounded-full transition-[padding,width,margin-left,opacity,padding,filter] whitespace-nowrap duration-200 overflow-hidden`,
                        props.assignedChildren.includes(child.id)
                          ? `px-3 py-0.5 w-auto ml-2 first:ml-0`
                          : `p-0 w-0 opacity-0 blur`,
                      )}
                    >
                      {child.name}
                    </Link>
                  ))}
                  <span
                    className={cx(
                      `text-sm bg-slate-100 text-slate-400 font-medium rounded overflow-hidden transition-[padding,width,opacity,filter] whitespace-nowrap`,
                      props.assignedChildren.length > 0
                        ? `p-0 w-0`
                        : `px-3 py-0.5 w-auto`,
                    )}
                  >
                    Not being used
                  </span>
                  <div className="relative z-20 mr-20 ml-2" ref={dropdownRef}>
                    <div
                      className={cx(
                        `absolute rounded-xl transition-[width,height,background-color,box-shadow,padding-top] duration-200 flex flex-col p-1.5 overflow-hidden`,
                        assignToChildExpanded
                          ? `w-40 h-auto shadow-xl shadow-slate-600/20 bg-slate-100 pt-7`
                          : `w-full h-full bg-slate-200`,
                      )}
                    >
                      {props.allChildren.map((c) => {
                        const selected = props.assignedChildren.includes(c.id);
                        return (
                          <button
                            className={cx(
                              `flex items-center gap-2 transition-[background-color,opacity,transform] duration-150 hover:bg-slate-200/50 active:bg-slate-200 active:scale-95 rounded-lg px-2 py-1`,
                              !assignToChildExpanded && `opacity-0`,
                            )}
                            onClick={() => props.toggleChild(c.id)}
                            key={c.id}
                          >
                            <div
                              className={cx(
                                `w-3.5 h-3.5 flex items-center justify-center rounded`,
                                selected ? `bg-violet-500` : `bg-slate-300/60`,
                              )}
                            >
                              <i
                                className={cx(
                                  `fa-solid fa-check text-[10px]`,
                                  selected ? `text-white` : `text-transparent`,
                                )}
                              />
                            </div>
                            <span className="text-sm font-medium whitespace-nowrap">
                              {c.name}
                            </span>
                          </button>
                        );
                      })}
                    </div>
                    <button
                      className={cx(
                        `w-6 h-6 flex items-center justify-center rounded-full relative transition-[transform,background-color] duration-200`,
                        assignToChildExpanded
                          ? `bg-slate-100 rotate-[135deg]`
                          : `bg-slate-200`,
                      )}
                      onClick={() => {
                        setAssignToChildExpanded(!assignToChildExpanded);
                      }}
                    >
                      <i className="fa-solid fa-plus text-slate-500" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
      {isSelect(props) || (
        <div
          className={cx(
            `w-full flex flex-col py-2 border-t border-slate-100 rounded-b-2xl`,
            isSelect(props) && props.selected && `bg-indigo-100/40`,
            props.mode === `keychains_screen` &&
              props.assignedChildren.length === 0 &&
              `bg-red-50/50 !border-red-100`,
          )}
        >
          <div className="flex justify-between">
            {isPublic ? (
              <Badge type="green" size="medium" className="ml-3 self-center">
                <UsersIcon className="w-3.5 h-3.5 mr-2 text-green-600 hidden min-[400px]:block" />
                {` `}
                Public
              </Badge>
            ) : (
              <div />
            )}
            {props.mode !== `select` && (
              <div className="flex items-center pr-2 gap-2">
                {props.mode === `assigned_to_child` && !props.schedule && (
                  <button
                    onClick={() => {
                      props.setSchedule(defaults.ruleSchedule());
                      setShowSchedule(true);
                    }}
                    className={cx(
                      `flex items-center px-2 py-1 rounded-full transition-[background-color,transform] duration-200 active:scale-90 gap-1.5 bg-slate-200/50 hover:bg-slate-200 active:bg-slate-300 select-none`,
                    )}
                  >
                    <ClockIcon
                      className={cx(`w-3.5 h-3.5 shrink-0 text-slate-500`)}
                      strokeWidth={2.5}
                    />
                    <span className="text-sm text-slate-600 font-medium">
                      Always active
                    </span>
                  </button>
                )}
                {props.mode === `assigned_to_child` && props.schedule && (
                  <button
                    onClick={() => {
                      setShowSchedule(!showSchedule);
                    }}
                    className={cx(
                      `flex items-center px-2 py-1 rounded-full transition-[background-color,transform] duration-200 active:scale-90 gap-1.5 bg-slate-200/50 hover:bg-slate-200 active:bg-slate-300 select-none`,
                    )}
                  >
                    <ChevronDownIcon
                      className={cx(
                        `w-3.5 h-3.5 shrink-0 text-slate-500 transition-transform duration-200`,
                        showSchedule && `-rotate-180`,
                      )}
                      strokeWidth={2.5}
                    />
                    <span className="text-sm text-slate-600 font-medium">Scheduled</span>
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
                {props.mode === `assigned_to_child` && !isPublic && (
                  <Button
                    type="link"
                    to={`/keychains/${props.keychainId}`}
                    color="tertiary"
                    size="small"
                    className="h-full flex items-center"
                  >
                    <div className="flex items-center block xs:hidden">
                      <i className="fa-solid fa-key ml-2" />
                      <i className="fa-solid fa-plus ml-2" />
                    </div>
                    <div className="flex items-center hidden xs:block">
                      <span>Add key</span>
                      <i className="fa-solid fa-arrow-right ml-2" />
                    </div>
                  </Button>
                )}
              </div>
            )}
          </div>
          {props.mode === `assigned_to_child` && props.schedule && (
            <div
              className={cx(
                `flex justify-center items-center gap-2 px-4 @container/schedule`,
                showSchedule ? ` mt-2` : `h-0 opacity-0 pointer-events-none mt-0`,
              )}
            >
              <ClockIcon className="w-4 text-slate-400 shrink-0" strokeWidth={2.5} />
              <SchedulePicker schedule={props.schedule} setSchedule={props.setSchedule} />
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
                  className="w-4 h-4 text-slate-400 group-hover:scale-75 transition-transform duration-200"
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
