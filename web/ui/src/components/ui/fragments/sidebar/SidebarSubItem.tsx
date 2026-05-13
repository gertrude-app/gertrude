import React from 'react';

interface Props {
  title: string;
}

const SidebarSubItem: React.FC<Props> = ({ title }) => {
  return (
    <div className="rounded-xl cursor-pointer relative group">
      <div className="absolute left-2.5 top-0 h-full w-0.25 bg-stone-200 group-last:h-[80%]" />
      <div className="py-1.75 hover:bg-stone-200/30 ml-5 px-2.5 rounded-xl active:bg-stone-200/50 active:scale-98 transition-[scale] duration-100">
        <span className="text-[15px] text-stone-900 select-none">{title}</span>
      </div>
    </div>
  );
};

export default SidebarSubItem;
