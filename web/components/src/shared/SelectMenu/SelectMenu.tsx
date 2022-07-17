import React from 'react';
import { Fragment } from 'react';
import { Listbox, Transition } from '@headlessui/react';
import cx from 'classnames';

interface Props {
  className?: string;
  options: string[];
  selectedOption: string;
  setSelected(value: string): void;
}

const SelectMenu: React.FC<Props> = ({
  className,
  options,
  selectedOption,
  setSelected,
}) => {
  return (
    <Listbox value={selectedOption} onChange={setSelected}>
      {({ open }) => (
        <>
          <Listbox.Label className="sr-only">Change published status</Listbox.Label>
          <div className="relative">
            <div className="rounded-md w-full shadow-sm">
              <div className="relative z-0 inline-flex rounded-md w-full border divide-x-2">
                <div className="relative flex flex-grow items-center bg-white py-2 pl-3 pr-4 border border-transparent rounded-l-md text-gray-700">
                  <p className="ml-2.5 font-medium">{selectedOption}</p>
                </div>
                <Listbox.Button className="relative inline-flex items-center p-4 rounded-l-none rounded-r-md text-sm font-medium text-white hover:bg-gray-100 focus:outline-none focus:z-10 focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-50 focus:ring-indigo-500 [transition:100ms] ">
                  <span className="sr-only">Change published status</span>
                  <i
                    className="fa fa-chevron-down text-xl text-gray-400"
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
              <Listbox.Options className="origin-top-right absolute z-10 right-0 mt-2 w-72 rounded-md shadow-lg overflow-hidden bg-white divide-y divide-gray-200 ring-1 ring-black ring-opacity-5 focus:outline-none">
                {options.map((option) => (
                  <Listbox.Option
                    key={option}
                    className={({ active }) =>
                      cx(
                        active ? 'text-white bg-indigo-500' : 'text-gray-900',
                        'cursor-pointer select-none relative p-4 text-sm',
                      )
                    }
                    value={option}
                  >
                    {({ selected, active }) => (
                      <div className="flex flex-col">
                        <div className="flex justify-between">
                          <p className={selected ? 'font-semibold' : 'font-normal'}>
                            {option}
                          </p>
                          {selected ? (
                            <span className={active ? 'text-white' : 'text-indigo-500'}>
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
};

export default SelectMenu;

// import React, { useState } from 'react';

// interface Props {
//   className?: string;
//   options: string[];
//   selected: string;
//   setSelected(value: string): void;
// }

// const SelectMenu: React.FC<Props> = ({ className, options, selected, setSelected }) => {
//   const [open, setOpen] = useState(false);

//   return (
//     <div
//       className={`flex justify-between items-stretch shadow-sm relative rounded-md bg-white ${className}`}
//     >
//       <h2 className="pl-4 border rounded-l-md flex-grow border-r-0 flex justify-start items-center leading-5">
//         {selected}
//       </h2>
//       <button
//         onClick={() => setOpen(!open)}
//         className="transition duration-100 rounded-r-md  py-4 px-5 border hover:bg-gray-50 focus:ring-4 ring-indigo-500 ring-offset-2"
//       >
//         <i
//           className={`fa fa-chevron-down text-gray-600 transition ${
//             open ? '-rotate-180' : 'rotate-0'
//           }`}
//         />
//       </button>
//       <div
//         className={`absolute bg-white shadow-lg rounded-xl z-40 right-0 top-16 border [transition:200ms] ${
//           open ? 'block opacity-100' : 'hidden opacity-0'
//         }`}
//       >
//         {options.map((option) => (
//           <div
//             className="py-3 px-5 last:pb-4 last:rounded-b-xl first:pt-4 first:rounded-t-xl hover:bg-indigo-500 hover:text-white cursor-pointer flex items-center"
//             onClick={() => {
//               setSelected(option);
//               setOpen(false);
//             }}
//           >
//             <i
//               className={`fa w-5 mr-4 ${
//                 option === selected ? 'text-gray-300 fa-check' : 'text-gray-200'
//               }`}
//             />
//             <h2
//               className={`leading-5 ${option === selected ? 'font-bold' : 'font-normal'}`}
//             >
//               {option}
//             </h2>
//           </div>
//         ))}
//       </div>
//     </div>
//   );
// };

// export default SelectMenu;
