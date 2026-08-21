import { Text } from '@gertrude/ui';
import cx from 'clsx';
import React from 'react';

type Props = {
  children: React.ReactNode;
  size?: `default` | `compact`;
  className?: string;
};

const MessageBubble: React.FC<Props> = ({ children, size = `default`, className }) => (
  <Text
    as="p"
    variant={size === `compact` ? `captionSubtle` : `body`}
    className={cx(
      `w-fit self-start rounded-tl`,
      size === `compact`
        ? `rounded-xl bg-stone-100 px-2.5 py-1.5 leading-4`
        : `rounded-2xl bg-stone-200 px-3.5 py-2.5`,
      className,
    )}
  >
    {children}
  </Text>
);

export default MessageBubble;
