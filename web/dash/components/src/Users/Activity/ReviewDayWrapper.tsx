import React from 'react';

const ReviewDayWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    id="delete-focus"
    className="px-0 py-5 bg-transparent flex-grow space-y-8 flex flex-col"
  >
    {children}
  </div>
);

export default ReviewDayWrapper;
