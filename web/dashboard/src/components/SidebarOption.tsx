import React from 'react';

interface Props {
  selected: boolean;
  icon: string;
  children: string;
}

const SidebarOption: React.FC<Props> = ({ selected, icon, children }) => {
  return (
    <div
      className={`flex justify-start items-center bg-black bg-opacity-0 px-5 py-3 rounded-xl cursor-pointer transition duration-75 my-3 ${
        selected ? 'bg-opacity-20' : 'hover:bg-opacity-10'
      }`}
    >
      <i className={`fa fa-${icon} mr-4 text-2xl text-white text-opacity-50`} />
      <h2 className="text-white text-2xl text-opacity-80 font-bold">{children}</h2>
    </div>
  );
};

export default SidebarOption;
