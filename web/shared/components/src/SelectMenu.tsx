import React from 'react';
import cx from 'classnames';
import { Fragment } from 'react';
import { Listbox, Transition } from '@headlessui/react';
import Label from './Label';

interface Props<Value extends string> {
  options: Array<{ value: Value; display: string }>;
  selectedOption: Value;
  setSelected(value: Value): void;
  label?: string;
  size?: 'small' | 'medium' | 'large';
  testId?: string;
  disabled?: boolean;
}

function SelectMenu<Value extends string = string>({
  options,
  selectedOption,
  setSelected,
  label,
  size = `large`,
  testId,
  disabled,
}: Parameters<React.FC<Props<Value>>>[0]): ReturnType<React.FC<Props<Value>>> {
  let buttonStyles = ``;
  switch (size) {
    case `small`:
      buttonStyles = `py-1 bg-white dark:bg-slate-900 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500 dark:text-slate-400 dark:ring-offset-slate-900`;
      break;
    case `medium`:
      buttonStyles = `py-2 bg-white text-slate-400 hover:bg-slate-100`;
      break;
    case `large`:
      buttonStyles = `py-3 bg-violet-800 text-white hover:bg-violet-900`;
      break;
  }
  return (
    <Listbox value={selectedOption} onChange={setSelected}>
      {({ open }) => (
        <div
          data-test={testId}
          className={cx(`relative`, disabled && `opacity-60 cursor-not-allowed`)}
        >
          {label && <Label className="w-full inline-block pb-px">{label}</Label>}
          <div className="relative">
            <div className="rounded-md w-full">
              <div className="relative z-0 inline-flex rounded-md w-full border dark:border-slate-700">
                <div className="relative flex flex-grow items-center bg-white dark:bg-slate-900 pl-3 pr-4 border border-transparent rounded-l-md text-slate-700 dark:text-slate-300">
                  <p className="ml-2.5 font-medium">
                    {(options.find((opt) => opt.value === selectedOption) ?? options[0])
                      ?.display ?? `make a selection...`}
                  </p>
                </div>
                <Listbox.Button
                  className={cx(
                    `relative inline-flex items-center px-4 rounded-l-none rounded-r-md text-sm font-medium focus:outline-none focus:z-10 focus:ring-2 focus:ring-offset-2 focus:ring-offset-slate-50 focus:ring-indigo-500 [transition:100ms]`,
                    buttonStyles,
                    disabled && `cursor-not-allowed pointer-events-none`,
                  )}
                >
                  <span className="sr-only">Change published status</span>
                  <i
                    className={`fa fa-chevron-down text-xl text-opacity-90 transition duration-100 ${
                      open ? `-rotate-180` : `rotate-0`
                    }`}
                    aria-hidden="true"
                  />
                </Listbox.Button>
              </div>
            </div>

            <Transition
              show={open}
              as={Fragment}
              leave="transition ease-in duration-100"
              leaveFrom="opacity-100"
              leaveTo="opacity-0"
            >
              <Listbox.Options className="origin-top-right absolute z-20 right-0 mt-2 w-72 rounded-md shadow-lg overflow-hidden bg-white dark:bg-slate-800 ring-1 ring-black ring-opacity-5 focus:outline-none">
                {options.map(({ value, display }) => (
                  <Listbox.Option
                    key={value}
                    className={({ active }) =>
                      cx(
                        active
                          ? `bg-violet-100 dark:text-slate-200`
                          : `text-slate-900 dark:text-slate-300`,
                        `cursor-pointer select-none relative`,
                        size === `small` ? `py-2 px-3` : `p-3.5 text-md`,
                        size === `small` && active && `bg-slate-50 dark:bg-slate-700/50`,
                      )
                    }
                    value={value}
                  >
                    {({ selected }) => (
                      <div className="flex flex-col">
                        <div className="flex justify-between">
                          <p className={selected ? `font-semibold` : `font-normal`}>
                            {display}
                          </p>
                          {selected ? (
                            <span className={`text-violet-700`}>
                              <i className="fa fa-check h-5 w-5" aria-hidden="true" />
                            </span>
                          ) : null}
                        </div>
                      </div>
                    )}
                  </Listbox.Option>
                ))}
              </Listbox.Options>
            </Transition>
          </div>
        </div>
      )}
    </Listbox>
  );
}

export default SelectMenu;
