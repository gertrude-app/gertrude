import React from 'react';

const ReviewDayWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    id="delete-focus"
    className="px-0 md:px-8 lg:px-10 py-5 md:py-10 pb-16 bg-slate-200 md:bg-transparent flex-grow space-y-8 flex flex-col"
  >
    {children}
  </div>
);

export default ReviewDayWrapper;
