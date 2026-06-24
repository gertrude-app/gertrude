import React from 'react';
import { Link } from 'react-router-dom';
import { UserIcon } from './Icons';

interface ConnectedAccount {
  parentId: string;
  parentEmail: string;
  childName: string;
}

const ConnectedAccountBadge: React.FC<{ account: ConnectedAccount }> = ({ account }) => (
  <Link
    to={`/parents/${account.parentId.toLowerCase()}`}
    className="group inline-flex items-center gap-2 rounded-full border border-violet-300 bg-white px-3 py-1.5 hover:bg-violet-50 transition-colors"
  >
    <UserIcon className="w-4 h-4 shrink-0 text-slate-400 group-hover:text-slate-500 transition-colors" />
    <span className="inline-flex items-center gap-1">
      <span className="text-sm font-semibold text-slate-900">{account.childName}</span>
      <span className="text-slate-300">&middot;</span>
      <span className="text-sm text-slate-500">{account.parentEmail}</span>
    </span>
  </Link>
);

export default ConnectedAccountBadge;
