import React, { useState } from 'react';

interface Props {
  className?: string;
  options: string[];
  selected: string;
  setSelected(value: string): void;
}

const SelectMenu: React.FC<Props> = ({ className, options, selected, setSelected }) => {
  const [open, setOpen] = useState(false);

  return (
    <div
      className={`flex justify-between items-stretch shadow-sm relative rounded-md bg-white ${className}`}
    >
      <h2 className="pl-4 border rounded-l-md flex-grow border-r-0 flex justify-start items-center leading-5">
        {selected}
      </h2>
      <button
        onClick={() => setOpen(!open)}
        className="transition duration-100 rounded-r-md  py-4 px-5 border hover:bg-gray-50 focus:ring-4 ring-indigo-500 ring-offset-2"
      >
        <i
          className={`fa fa-chevron-down text-gray-600 transition ${
            open ? '-rotate-180' : 'rotate-0'
          }`}
        />
      </button>
      <div
        className={`absolute bg-white shadow-lg rounded-xl z-40 right-0 top-16 border [transition:200ms] ${
          open ? 'block opacity-100' : 'hidden opacity-0'
        }`}
      >
        {options.map((option) => (
          <div
            className="py-3 px-5 last:pb-4 last:rounded-b-xl first:pt-4 first:rounded-t-xl hover:bg-indigo-500 hover:text-white cursor-pointer flex items-center"
            onClick={() => {
              setSelected(option);
              setOpen(false);
            }}
          >
            <i
              className={`fa w-5 mr-4 ${
                option === selected ? 'text-gray-300 fa-check' : 'text-gray-200'
              }`}
            />
            <h2
              className={`leading-5 ${option === selected ? 'font-bold' : 'font-normal'}`}
            >
              {option}
            </h2>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SelectMenu;
