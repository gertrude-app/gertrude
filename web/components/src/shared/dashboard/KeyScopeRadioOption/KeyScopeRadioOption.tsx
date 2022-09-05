import React from 'react';

type Props = {
  className?: string;
  icon: string;
  title: string;
  description: string;
  selected: boolean;
  onClick(): void;
};

const KeyScopeRadioOption: React.FC<Props> = ({
  className,
  icon,
  title,
  description,
  selected,
  onClick,
}) => <h1>KeyScopeRadioOption placeholder</h1>;

export default KeyScopeRadioOption;
