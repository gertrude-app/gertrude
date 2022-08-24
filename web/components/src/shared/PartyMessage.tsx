import React from 'react';

const PartyMessage: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <p className="italic antialiased text-sm text-gray-600">
    {children}
    <span role="img" aria-hidden className="pl-1.5 not-italic">
      🎉
    </span>
  </p>
);

export default PartyMessage;
