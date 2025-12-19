import React from 'react';

interface ListStepProps {
  children: React.ReactNode;
  index: number;
}

const ListStep: React.FC<ListStepProps> = ({ children, index }) => (
  <li className="bg-slate-50/50 rounded-2xl border-[0.5px] border-slate-200 p-3 xs:p-4 [&_a]:text-indigo-500 relative shadow-sm">
    <div className="absolute w-10 xs:w-12 h-10 xs:h-12 -left-3 md:-left-4 top-1 md:-top-2 rounded-full bg-white shadow-md flex justify-center items-center">
      <span className="font-semibold text-xl xs:text-2xl">{index}</span>
    </div>
    <p className="ml-8 xs:ml-10 text-slate-600 font-medium text-sm xs:text-base">
      {children}
    </p>
  </li>
);

export default ListStep;
