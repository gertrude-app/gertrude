import cx from 'clsx';
import { CheckIcon } from 'lucide-react';
import React from 'react';
import HStack from './HStack';

interface Props {
  selected: boolean;
}

const SelectionCircle: React.FC<Props> = ({ selected }) => (
  <HStack
    as="span"
    justify="center"
    aria-hidden="true"
    className={cx(
      `w-5 h-5 rounded-full border shrink-0`,
      selected ? `bg-violet-500 border-violet-500` : `bg-white border-stone-200`,
    )}
  >
    <CheckIcon className="w-3.5 h-3.5 text-white translate-y-[0.5px]" strokeWidth={3} />
  </HStack>
);

export default SelectionCircle;
