import React, { useState } from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import { Toggle } from '@dash/components';

const testRequests: Array<{
  time: string;
  protocol: 'UDP' | 'TCP';
  address: string;
  app: string;
  number: number;
  id: string;
}> = [
  {
    time: '10:04:34PM',
    protocol: 'TCP',
    address: 'google.com',
    app: 'Firefox Browser',
    number: 2,
    id: '1',
  },
  {
    time: '10:03:56PM',
    protocol: 'TCP',
    address: 'guzzoni.apple.com',
    app: '.com.apple.assistantd',
    number: 1,
    id: '2',
  },
  {
    time: '10:02:28PM',
    protocol: 'TCP',
    address: 'khanacademy.com',
    app: 'Firefox Browser',
    number: 4,
    id: '3',
  },
  {
    time: '10:02:11PM',
    protocol: 'UDP',
    address: '172.64.80.1',
    app: 'Firefox Browser',
    number: 1,
    id: '4',
  },
  {
    time: '10:00:02PM',
    protocol: 'TCP',
    address: 'https://bag.itunes.apple.com/bag.xml?deviceClass=Macintosh&format=json',
    app: '.com.apple.appstoreagent',
    number: 12,
    id: '5',
  },
  {
    time: '09:58:46PM',
    protocol: 'TCP',
    address: 'outlook.office365.com/foo/barbaz',
    app: 'Firefox Browser',
    number: 3,
    id: '6',
  },
  {
    time: '09:54:34PM',
    protocol: 'UDP',
    address: '172.64.80.1',
    app: 'Firefox Browser',
    number: 1,
    id: '7',
  },
];

interface Props {}

const NetworkTraffic: React.FC<Props> = ({}) => {
  const [filterQuery, setFilterQuery] = useState('');
  const [TCPOnly, setTCPOnly] = useState(true);
  const [blocksOnly, setBlocksOnly] = useState(true);

  return (
    <div className="bg-white h-full flex flex-col rounded-b-xl">
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
        <div className="flex items-center space-x-6">
          <div className="flex items-center space-x-2">
            <Toggle enabled={TCPOnly} setEnabled={() => setTCPOnly(!TCPOnly)} small />
            <span className="text-slate-700 font-medium">TCP only</span>
          </div>
          <div className="flex items-center space-x-2">
            <Toggle
              enabled={blocksOnly}
              setEnabled={() => setBlocksOnly(!blocksOnly)}
              small
            />
            <span className="text-slate-700 font-medium">Blocks only</span>
          </div>
        </div>
        {/* @ts-ignore */}
        <Button color="tertiary" size="small" type="button" onClick={() => {}}>
          <i className="fa-solid fa-ban mr-2 text-red-400" />
          Clear requests
        </Button>
      </header>
      <div className="flex flex-col p-4 flex-grow">
        {testRequests
          .filter((req) => req.address.toUpperCase().includes(filterQuery.toUpperCase()))
          .filter((req) => (TCPOnly ? req.protocol === 'TCP' : true))
          .map((req) => (
            <NetworkRequest {...req} key={req.id} />
          ))}
      </div>
    </div>
  );
};

export default NetworkTraffic;

interface Props {
  time: string;
  protocol: 'UDP' | 'TCP';
  address: string;
  app: string;
  number: number;
  id: string;
}

const NetworkRequest: React.FC<Props> = ({
  time,
  protocol,
  address,
  app,
  number,
  id,
}) => {
  const [selected, setSelected] = useState(false);
  return (
    <div className="flex items-center justify-between p-3 rounded-xl even:bg-slate-50">
      <div className="flex items-center">
        <div
          className={cx(
            'border w-6 h-6 rounded-full transition duration-100 hover:scale-105 cursor-pointer flex justify-center items-center shrink-0',
            selected
              ? 'bg-violet-700 border-violet-700'
              : 'border-slate-300 hover:border-slate-400 ',
          )}
          onClick={() => setSelected(!selected)}
        >
          <i
            className={cx(
              'fa-solid fa-check text-white even:text-slate-50 text-sm transition duration-150',
              selected ? 'scale-100' : 'scale-50',
            )}
          />
        </div>
        <span className="text-xs text-slate-400/80 ml-4 font-mono">{time}</span>
        <span
          className={cx(
            'text-white font-medium text-sm px-2 rounded-full ml-6 opacity-80',
            protocol === 'TCP' ? 'bg-indigo-500' : 'bg-fuchsia-500',
          )}
        >
          {protocol}
        </span>
        <span className="text-sm font-mono ml-6 text-slate-800 max-w-sm text-ellipsis overflow-hidden block whitespace-nowrap">
          {address}
        </span>
      </div>
      <span className="shrink-0 max-w-[220px] overflow-hidden whitespace-nowrap text-ellipsis text-slate-400 font-medium">
        {app}
      </span>
    </div>
  );
};
