import cx from 'classnames';
import React from 'react';
import type { AdminData } from '@/lib/types';
import { isActive } from '@/lib/utils';

const OverallStatsBlock: React.FC<{ admins: AdminData[] }> = ({ admins }) => {
  const adminCount = admins.length;
  const activeAdminCount = admins.filter(isActive).length;
  const userCount = admins.reduce((acc, admin) => acc + admin.children.length, 0);
  const computerCount = admins
    .flatMap((admin) => admin.children)
    .reduce((acc, child) => acc + child.installations.length, 0);
  const annualRevenue = admins.reduce((total, admin) => {
    if (admin.subscriptionStatus === `paid`) {
      return total + admin.monthlyPriceInDollars * 12;
    } else {
      return total;
    }
  }, 0);
  const payingAdmins = admins.filter((a) => a.subscriptionStatus === `paid`);
  const payingAdminCount = payingAdmins.length;
  const activelyProtectedChildrenCount = admins
    .filter(isActive)
    .reduce(
      (acc, admin) =>
        acc +
        admin.children.filter(
          (child) =>
            child.keyloggingEnabled || child.screenshotsEnabled || child.numKeys > 0,
        ).length,
      0,
    );

  return (
    <div className="border rounded-3xl p-6 flex flex-col items-start gap-8">
      <Stat
        title="Annual revenue"
        value={`$${annualRevenue.toLocaleString()}`}
        size="lg"
      />
      <div className="flex gap-8 items-center">
        <Stat title="Paying admins" value={payingAdminCount} size="md" />
        <Stat title="Active admins" value={activeAdminCount} size="md" />
        <Stat
          title="Actively protected children"
          value={activelyProtectedChildrenCount}
          size="md"
        />
      </div>
      <div className="flex gap-8 items-center">
        <Stat title="All-time signups" value={adminCount} size="sm" />
        <Stat title="All-time children" value={userCount} size="sm" />
        <Stat title="All-time app installations" value={computerCount} size="sm" />
      </div>
    </div>
  );
};

export default OverallStatsBlock;

const Stat: React.FC<{
  title: string;
  value: any;
  size: `sm` | `md` | `lg`;
}> = ({ title, value, size }) => (
  <div className="flex flex-col items-start">
    <span
      className={cx(`font-bold`, {
        'text-2xl !font-medium': size === `sm`,
        'text-5xl': size === `md`,
        'text-6xl': size === `lg`,
      })}
    >
      {value.toLocaleString()}
    </span>
    <span className="text-slate-500">{title}</span>
  </div>
);
