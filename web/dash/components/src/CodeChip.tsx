import cx from 'classnames';
import React from 'react';

export type Props = {
  code: string | number;
  size?: `md` | `lg`;
  pill?: `sm` | `lg` | false;
  className?: string;
  testId?: string;
};

const CodeChip: React.FC<Props> = ({
  code,
  size = `lg`,
  pill = `sm`,
  className,
  testId,
}) => (
  <code
    data-test={testId}
    className={cx(
      `text-fuchsia-700 tracking-widest font-bold`,
      size === `lg` ? `text-3xl` : `text-2xl`,
      pill === `sm` && `block bg-fuchsia-50 w-fit self-center px-4 py-1 rounded-lg`,
      pill === `lg` && `block bg-fuchsia-50 px-6 py-3 rounded-xl`,
      className,
    )}
  >
    {code}
  </code>
);

export default CodeChip;
