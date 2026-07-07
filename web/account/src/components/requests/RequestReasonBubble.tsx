import { Text } from '@gertrude/ui';
import cx from 'clsx';
import React from 'react';

type Props = {
  children: React.ReactNode;
  className?: string;
};

const RequestReasonBubble: React.FC<Props> = ({ children, className }) => (
  <Text
    as="p"
    variant="body"
    className={cx(
      `w-fit self-start rounded-2xl rounded-tl bg-stone-200 px-3.5 py-2.5`,
      className,
    )}
  >
    {children}
  </Text>
);

export default RequestReasonBubble;
