import React from 'react';

interface Props {
  content: React.ReactNode;
  children: React.ReactNode;
}

const SidebarLayout: React.FC<Props> = ({ content, children }) => {
  return (
    <div className="flex min-h-screen">
      {children}
      <main className="flex-grow">{content}</main>
    </div>
  );
};

export default SidebarLayout;
