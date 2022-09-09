import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  prefix: string;
  data: string;
  dataFormat?: string;
};

const SummaryLi: React.FC<Props> = ({ className, prefix, data, dataFormat }) => (
  <li className={cx('odd:bg-violet-50 p-2 rounded-lg font-medium list-none', className)}>
    {prefix}: <span className={dataFormat || 'font-bold text-gray-700'}>{data}</span>
  </li>
);

export default SummaryLi;
