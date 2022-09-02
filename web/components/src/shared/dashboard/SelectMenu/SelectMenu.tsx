import React from 'react';
import { Fragment } from 'react';
import { Listbox, Transition } from '@headlessui/react';
import cx from 'classnames';

interface Props {
  options: Array<{ value: string; display: string }>;
  selectedOption: string;
  setSelected(value: string): void;
}

const SelectMenu: React.FC<Props> = ({ options, selectedOption, setSelected }) => (
  <Listbox value={selectedOption} onChange={setSelected}>
    {({ open }) => (
      <>
        <Listbox.Label className="sr-only">Change published status</Listbox.Label>
        <div className="relative">
          <div className="rounded-md w-full shadow-sm">
            <div className="relative z-0 inline-flex rounded-md w-full border">
              <div className="relative flex flex-grow items-center bg-white pl-3 pr-4 border border-transparent rounded-l-md text-gray-700">
                <p className="ml-2.5 font-medium">
                  {(options.find((opt) => opt.value === selectedOption) ?? options[0])
                    ?.display ?? `make a selection...`}
                </p>
              </div>
              <Listbox.Button className="relative inline-flex items-center px-4 py-3.5 bg-violet-800 rounded-l-none rounded-r-md text-sm font-medium text-white hover:bg-violet-900 focus:outline-none focus:z-10 focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-50 focus:ring-indigo-500 [transition:100ms] ">
                <span className="sr-only">Change published status</span>
                <i
                  className={`fa fa-chevron-down text-xl text-white text-opacity-90 transition duration-100 ${
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
            <Listbox.Options className="origin-top-right absolute z-10 right-0 mt-2 w-72 rounded-md shadow-lg overflow-hidden bg-white ring-1 ring-black ring-opacity-5 focus:outline-none">
              {options.map(({ value, display }) => (
                <Listbox.Option
                  key={value}
                  className={({ active }) =>
                    cx(
                      active
                        ? `text-white bg-violet-800`
                        : `text-gray-900 even:bg-gray-50`,
                      `cursor-pointer select-none relative p-4 text-md`,
                    )
                  }
                  value={value}
                >
                  {({ selected, active }) => (
                    <div className="flex flex-col">
                      <div className="flex justify-between">
                        <p className={selected ? `font-semibold` : `font-normal`}>
                          {display}
                        </p>
                        {selected ? (
                          <span className={active ? `text-white` : `text-violet-700`}>
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
      </>
    )}
  </Listbox>
);

export default SelectMenu;
