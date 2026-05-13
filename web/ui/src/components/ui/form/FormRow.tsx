import React from 'react';

interface Props {
  children: React.ReactNode;
  label?: string;
  description?: string;
}

const FormRow: React.FC<Props> = ({ children, label, description }) => {
  return (
    <div className="flex items-center justify-between border-t border-stone-200 py-4 first:border-none">
      <div className="flex flex-col">
        {label && <span className="text-sm font-medium text-stone-800">{label}</span>}
        {description && <span className="text-xs text-stone-500">{description}</span>}
      </div>
      <div>{children}</div>
    </div>
  );
};

export default FormRow;
