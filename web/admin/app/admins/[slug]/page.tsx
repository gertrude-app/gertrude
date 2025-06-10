import cx from 'classnames';
import { notFound } from 'next/navigation';
import React from 'react';
import SubscriptionStatusBadge from '@/components/SubscriptionStatusBadge';
import getAdminData from '@/lib/get-data';

const IndividualAdminPage: React.FC<{ params: { slug: string } }> = async ({
  params,
}) => {
  const admins = await getAdminData();
  if (!admins.success) {
    return <div>{admins.error}</div>;
  }
  const admin = admins.data.find((admin) => admin.id === params.slug);
  if (!admin) {
    return notFound();
  }

  return (
    <div className="p-12">
      <div className={cx(`border rounded-3xl flex flex-col`)}>
        <div className="p-8">
          <SubscriptionStatusBadge status={admin.subscriptionStatus} />
          <h1 className="text-3xl font-semibold my-2">{admin.email}</h1>
          <h2 className="text-slate-400">{admin.id}</h2>
        </div>
        <div className="flex gap-8 items-start text-slate-500 py-4 px-8 bg-slate-50 rounded-b-3xl border-t">
          <span>
            <span className="font-semibold text-lg text-slate-700">
              {admin.children.length}
            </span>
            {` `}
            {admin.children.length === 1 ? `child` : `children`}
          </span>
          <span>
            <span className="font-semibold text-lg text-slate-700">
              {admin.numKeychains}
            </span>
            {` `}
            keychain
            {admin.numKeychains !== 1 && `s`}
          </span>
          <span>
            <span className="font-semibold text-lg text-slate-700">
              {admin.numNotifications}
            </span>
            {` `}
            notification method
            {admin.numNotifications !== 1 && `s`}
          </span>
        </div>
      </div>
      <h2 className="text-3xl font-semibold mt-16 ml-8">Children:</h2>
      <div className="border rounded-3xl p-8 mt-4 bg-slate-50 flex flex-wrap gap-8">
        {admin.children.length === 0 && (
          <div className="w-full flex justify-center items-center h-40 text-2xl text-slate-400">
            No children
          </div>
        )}
        {admin.children.map((child) => (
          <div
            className="p-6 rounded-3xl bg-white border w-[420px] relative"
            key={child.name + child.createdAt}
          >
            <span className="absolute right-6 top-4 text-slate-400">
              {child.numKeys} keys
            </span>
            <h3 className="text-2xl font-semibold max-w-xs">{child.name}</h3>
            <div className="flex gap-2 mt-3">
              <div
                className={cx(
                  `text-sm px-3 py-0.5 rounded-full`,
                  child.screenshotsEnabled
                    ? `bg-blue-100 text-blue-700`
                    : `bg-slate-100 text-slate-400`,
                )}
              >
                Screenshots
              </div>
              <div
                className={cx(
                  `text-sm px-3 py-0.5 rounded-full`,
                  child.screenshotsEnabled
                    ? `bg-blue-100 text-blue-700`
                    : `bg-slate-100 text-slate-400`,
                )}
              >
                Keylogging
              </div>
            </div>
            <div className="mt-4 flex flex-col gap-2">
              {child.installations.length === 0 && (
                <div className="bg-slate-50 p-4 flex justify-center items-center rounded-2xl text-lg text-slate-400 font-medium">
                  No app installations
                </div>
              )}
              {child.installations.map((install) => (
                <div
                  className="bg-slate-50 rounded-xl p-4 flex justify-between items-center"
                  key={install.modelIdentifier}
                >
                  <div className="flex flex-col">
                    {install.osVersionName && install.osVersionNumber ? (
                      <span className="text-sm font-medium text-violet-500 bg-violet-100 rounded w-fit px-2 py-0.5 mb-2">
                        {install.osVersionName} ({install.osVersionNumber})
                      </span>
                    ) : (
                      <span className="text-sm font-medium text-slate-400 mb-2 pb-0.5">
                        Unknown OS
                      </span>
                    )}
                    <span className="font-semibold text-lg">
                      {install.modelIdentifier}
                    </span>
                    <span className="text-slate-500 text-sm">
                      App version:{` `}
                      <span className="font-semibold">{install.appVersion}</span>
                    </span>
                    <span className="text-slate-500 text-sm">
                      Filter version:{` `}
                      <span className="font-semibold">{install.filterVersion}</span>
                    </span>
                    <span className="text-slate-500 text-sm">
                      Release channel:{` `}
                      <span className="font-semibold">{install.appReleaseChannel}</span>
                    </span>
                  </div>
                  <img
                    src={`https://parents.gertrude.app/macs/${install.modelIdentifier}.png`}
                    alt="Mac computer"
                    className="w-16 h-16 object-contain object-center"
                  />
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default IndividualAdminPage;
