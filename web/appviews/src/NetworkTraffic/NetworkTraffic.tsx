import React, { useState } from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

interface Props {}

const NetworkTraffic: React.FC<Props> = ({}) => {
  const [filterQuery, setFilterQuery] = useState('');
  return (
    <div className="bg-white">
      <header className="flex justify-between items-center p-4 border-b border-slate-200">
        <div className="flex items-center">
          <input
            className="bg-slate-50 rounded-xl px-4 py-2 w-80 transition duration-100 focus:bg-slate-50 focus:shadow-md outline-none border-[0.5px] placeholder:text-slate-400"
            placeholder="Filter..."
            value={filterQuery}
            // @ts-ignore
            onChange={(e) => setFilterQuery(e.target.value)}
          />
          <button
            className={cx(
              'border border-slate-200 w-7 h-7 rounded-full ml-3 hover:bg-slate-50 transition duration-100 flex justify-center items-center',
              filterQuery
                ? 'opacity-100 translate-y-0 cursor-pointer'
                : 'opacity-0 translate-y-1 cursor-default',
            )}
            onClick={() => setFilterQuery('')}
          >
            <i className="fa-solid fa-times text-slate-500 text-sm" />
          </button>
        </div>
        {/* @ts-ignore */}
        <Button color="tertiary" size="small" type="button" onClick={() => {}}>
          <i className="fa-solid fa-ban mr-2 text-red-400" />
          Clear requests
        </Button>
      </header>
    </div>
  );
};

export default NetworkTraffic;
