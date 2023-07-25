import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

interface Props {
  name?: string;
  id: string;
  modelTitle: string;
  modelIdentifier: string;
  onlineUser?: string;
}

const ComputerCard: React.FC<Props> = ({
  name,
  modelTitle,
  onlineUser,
  modelIdentifier,
  id,
}) => (
  <div className="border-[0.5px] border-slate-200 rounded-3xl shadow-lg shadow-slate-300/50 bg-white">
    <div className="p-6 flex justify-between items-center gap-4">
      <div>
        <h2 className="text-2xl font-bold">{name || modelTitle}</h2>
        {name && <h3 className="text-sm text-slate-500">{modelTitle}</h3>}
      </div>
      <div className="w-20 h-20 flex justify-center items-center shrink-0">
        <img
          alt={modelTitle}
          src={`/macs/${modelIdentifier}.png`}
          className="max-h-full max-w-full"
        />
      </div>
    </div>
    <div className="p-4 bg-slate-50 rounded-b-3xl flex justify-between items-center">
      <div className="flex justify-end items-center gap-2 ml-2">
        <div
          className={cx(
            `w-3 h-3 rounded-full`,
            onlineUser ? `bg-green-400` : `bg-slate-100 shadow-inner`,
          )}
        />
        <span className="text-xs text-slate-400">
          {onlineUser ? `${onlineUser} is online` : `offline`}
        </span>
      </div>
      <Button type="link" to={`/computers/${id}`} color="tertiary" size="small">
        <i className="fa-solid fa-pen mr-2" />
        Edit
      </Button>
    </div>
  </div>
);

export default ComputerCard;
