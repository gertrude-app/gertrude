import React from 'react';
import type { NextPage } from 'next';
import AdminCard from '@/components/AdminCard';
import getAdminData from '@/lib/get-data';
import { isActive } from '@/lib/utils';

const AdminsPage: NextPage = async () => {
  const admins = await getAdminData();
  if (!admins.success) {
    return <div>{admins.error}</div>;
  }

  return (
    <div className="p-12 flex flex-col">
      <h1 className="text-4xl font-semibold">Gertrude Parents</h1>
      <p className="mb-4 mt-2 text-xl font-medium text-slate-600">
        <span className="font-mono font-bold text-black">{admins.data.length}</span>
        {` `}
        parent accounts,{` `}
        <span className="font-mono font-bold text-black">
          {admins.data.filter(isActive).length}
        </span>
        {` `}
        active,{` `}
        <span className="font-mono font-bold text-black">
          {admins.data.filter((admin) => admin.subscriptionStatus === `paid`).length}
        </span>
        {` `}
        paid
      </p>
      <ul className="flex items-center mb-8 gap-6">
        <li className="flex items-center gap-2">
          <div className="w-2 h-5 rounded-full bg-slate-200" />
          <span className="text-slate-500">Not onboarded</span>
        </li>
        <li className="flex items-center gap-2">
          <div className="w-2 h-5 rounded-full bg-yellow-500" />
          <span className="text-slate-500">Onboarded but inactive</span>
        </li>
        <li className="flex items-center gap-2">
          <div className="w-2 h-5 rounded-full bg-blue-500" />
          <span className="text-slate-500">Just monitoring</span>
        </li>
        <li className="flex items-center gap-2">
          <div className="w-2 h-5 rounded-full bg-green-500" />
          <span className="text-slate-500">Just using keychains</span>
        </li>
        <li className="flex items-center gap-2">
          <div className="w-2 h-5 rounded-full bg-gradient-to-b from-green-500 to-blue-500" />
          <span className="text-slate-500">Using keychains and monitoring</span>
        </li>
      </ul>
      <div className="flex flex-col">
        {admins.data
          .sort(
            (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
          )
          .map((admin) => (
            <AdminCard key={admin.id} admin={admin} />
          ))}
      </div>
    </div>
  );
};

export default AdminsPage;
