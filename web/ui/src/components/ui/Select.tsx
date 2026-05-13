import React from 'react';

interface Props {
  selected: string;
  setSelected: (selected: string) => void;
  possibleValues: string[];
  label?: string;
}

const Select: React.FC<Props> = () => {
  // TODO: will be a fairly thin wrapper around DropdownMenu
  return <div>Select</div>;
};

export default Select;
