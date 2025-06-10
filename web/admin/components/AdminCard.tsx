import cx from 'classnames';
import Link from 'next/link';
import React from 'react';
import type { AdminData } from '@/lib/types';
import { getStatus } from '@/lib/utils';

const AdminCard: React.FC<{ admin: AdminData }> = ({ admin }) => (
  <Link
    href={`/admins/${admin.id}`}
    className="flex odd:bg-slate-50 px-4 py-2 rounded-lg hover:z-10 border border-transparent hover:border-slate-400 relative"
  >
    {admin.subscriptionStatus === `paid` && (
      <>
        <span className="text-4xl font-mono font-bold text-green-500 absolute -left-6 top-4">
          $
        </span>
        <span className="text-4xl font-mono font-bold text-green-500 absolute -left-6 top-4 animate-ping">
          $
        </span>
      </>
    )}
    <div
      className={cx(`w-2 my-1 rounded-full mr-6`, {
        'bg-slate-200': getStatus(admin) === `nada`,
        'bg-yellow-500': getStatus(admin) === `onboardedButInactive`,
        'bg-blue-500': getStatus(admin) === `justMonitoring`,
        'bg-green-500': getStatus(admin) === `justKeychains`,
        'bg-gradient-to-b from-green-500 to-blue-500': getStatus(admin) === `superUser`,
      })}
    />
    <div className="flex flex-col flex-grow">
      <div className="flex items-center">
        <h2 className="font-medium text-lg">{admin.email}</h2>
        <div className="flex-grow" />
        <span className="text-sm bg-slate-200/50 text-slate-500 font-medium rounded-full px-2 py-0.5">
          {new Date(admin.createdAt).toLocaleTimeString(`en-US`, {
            hour: `numeric`,
            minute: `numeric`,
          })}
          {`, `}
          {new Date(admin.createdAt).toLocaleDateString(`en-US`, {
            year: `numeric`,
            month: `short`,
            day: `numeric`,
          })}
        </span>
      </div>
      <div className="flex items-center justify-between mt-2">
        <div className="flex items-center">
          <span className="mr-2 text-sm text-slate-400">a/b:</span>
          <span
            className={cx(
              `font-mono font-semibold w-12 rounded-full text-sm flex justify-center items-center`,
              {
                'bg-slate-200 text-slate-500': !admin.abTestVariant,
                'bg-violet-200 text-violet-500': admin.abTestVariant === `old_site`,
                'bg-fuchsia-200 text-fuchsia-500': admin.abTestVariant === `new_site`,
              },
            )}
          >
            {admin.abTestVariant === `old_site`
              ? `old`
              : admin.abTestVariant === `new_site`
                ? `new`
                : `?`}
          </span>
          <span
            className={cx(
              `text-sm ml-4 font-mono font-semibold rounded-full flex justify-center items-center px-3`,
              admin.hasGclid
                ? `bg-orange-100 text-orange-500`
                : `bg-slate-100 text-slate-300`,
            )}
          >
            Google click id
          </span>
          <span className="mr-2 ml-4 text-sm text-slate-400">status:</span>
          <span
            className={cx(`font-mono font-semibold rounded-full text-sm px-4`, {
              'bg-yellow-100 text-yellow-600': admin.subscriptionStatus === `trialing`,
              'bg-blue-100 text-blue-600': admin.subscriptionStatus === `complimentary`,
              'bg-orange-100 text-orange-600':
                admin.subscriptionStatus === `trialExpiringSoon`,
              'bg-red-100 text-red-600': admin.subscriptionStatus === `overdue`,
              'bg-slate-100 text-slate-300': admin.subscriptionStatus === `unpaid`,
              'bg-green-100 text-green-600': admin.subscriptionStatus === `paid`,
              'bg-pink-100 text-pink-600':
                admin.subscriptionStatus === `pendingEmailVerification`,
            })}
          >
            {admin.subscriptionStatus}
          </span>
        </div>
        <span className="text-slate-500 font-medium">
          {admin.children.length} kids • {admin.numKeychains} keychains •{` `}
          {admin.numNotifications} notifs
        </span>
      </div>
    </div>
  </Link>
);

export default AdminCard;
