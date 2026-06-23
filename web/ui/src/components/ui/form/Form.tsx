import React from 'react';

interface Props {
  children: React.ReactNode;
}

const Form: React.FC<Props> = ({ children }) => (
  <div className="flex flex-col">{children}</div>
);

export default Form;
