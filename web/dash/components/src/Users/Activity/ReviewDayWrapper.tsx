import React from 'react';

const ReviewDayWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="px-0 py-5 bg-transparent flex-grow gap-8 flex flex-col">{children}</div>
);

export default ReviewDayWrapper;
