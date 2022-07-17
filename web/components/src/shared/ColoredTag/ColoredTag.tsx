import React from 'react';

type Props = {
  className?: string;
  type:
    | 'active'
    | 'pending verification'
    | 'verified'
    | 'incomplete'
    | 'incomplete expired'
    | 'trialing'
    | 'past due'
    | 'canceled'
    | 'unpaid'
    | 'complementary';
};

const ColoredTag: React.FC<Props> = ({ type, className }) => {
  let colors = ``;

  switch (type) {
    case `active`:
      colors = `bg-green-200 text-green-800`;
      break;
    case `pending verification`:
      colors = `bg-yellow-200 text-yellow-800`;
      break;
    case `verified`:
      colors = `bg-blue-200 text-blue-800`;
      break;
    case `incomplete`:
      colors = `bg-orange-200 text-orange-800`;
      break;
    case `incomplete expired`:
      colors = `bg-red-200 text-red-800`;
      break;
    case `trialing`:
      colors = `bg-teal-200 text-teal-800`;
      break;
    case `past due`:
      colors = `bg-red-200 text-red-800`;
      break;
    case `canceled`:
      colors = `bg-gray-200 text-gray-800`;
      break;
    case `unpaid`:
      colors = `bg-red-200 text-red-800`;
      break;
    case `complementary`:
      colors = `bg-fuchsia-200 text-fuchsia-800`;
      break;
  }

  return (
    <h3 className={`px-6 py-0.5 rounded-full max-w-fit ${colors} ${className}`}>
      {type}
    </h3>
  );
};

export default ColoredTag;
