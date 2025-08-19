import React from 'react';

const TrashBtn: React.FC<{ onClick: () => unknown }> = ({ onClick }) => (
  <button
    onClick={(event) => {
      event.stopPropagation();
      onClick();
    }}
    className="text-slate-400 flex justify-center items-center rounded-full w-8 h-8 bg-transparent hover:bg-red-50 hover:text-red-500 shrink-0 ml-1"
  >
    <i className="fa-solid fa-trash" />
  </button>
);

export default TrashBtn;
