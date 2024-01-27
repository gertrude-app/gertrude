import React from 'react';
import cx from 'classnames';
import { TextInput, Button, PillBadge } from '@shared/components';
import type {
  AdminSubscriptionStatus,
  AdminNotificationTrigger,
  PendingNotificationMethod,
  Subcomponents,
  ConfirmableEntityAction,
  NewAdminNotificationMethodEvent,
  RequestState,
} from '@dash/types';
import { ConfirmDeleteEntity } from '../Modal';
import EmptyState from '../EmptyState';
import PageHeading from '../PageHeading';
import NewNotificationMethodSidebar from './NewNotificationMethodForm';
import NotificationCard from './NotificationCard';
import NotificationMethod from './NotificationMethod';

export type NotificationUpdate = { id: UUID } & (
  | { type: 'startEditing' }
  | { type: 'cancelEditing' }
  | { type: 'changeTrigger'; trigger: AdminNotificationTrigger }
  | { type: 'changeMethod'; methodId: UUID }
);

interface Props {
  email: string;
  status: AdminSubscriptionStatus;
  billingPortalRequest: RequestState<{ url: string }>;
  pendingMethod?: PendingNotificationMethod;
  methods: Subcomponents<typeof NotificationMethod>;
  notifications: Subcomponents<typeof NotificationCard>;
  deleteNotification: ConfirmableEntityAction;
  deleteMethod: ConfirmableEntityAction;
  updateNotification(update: NotificationUpdate): unknown;
  saveNotification(id: UUID): unknown;
  createNotification(): unknown;
  manageSubscription(): unknown;
  newMethodEventHandler(event: NewAdminNotificationMethodEvent): unknown;
}

const Settings: React.FC<Props> = ({
  email,
  status,
  methods,
  notifications,
  updateNotification,
  saveNotification,
  deleteNotification,
  createNotification,
  deleteMethod,
  pendingMethod,
  newMethodEventHandler,
  billingPortalRequest,
  manageSubscription,
}) => (
  <div className="relative">
    <ConfirmDeleteEntity type="notification" action={deleteNotification} />
    <ConfirmDeleteEntity type="notification method" action={deleteMethod} />
    <div
      className={cx(
        `absolute left-0 top-0 w-full h-full z-20 bg-slate-50 bg-opacity-60`,
        pendingMethod ? `block` : `hidden`,
      )}
    />
    <div
      className={cx(
        `fixed bg-white top-0 right-0 w-76 md:w-96 h-screen border-l border-slate-200 shadow-xl transition-[margin-right] z-30 flex flex-col justify-beween`,
        pendingMethod ? `mr-0` : `-mr-112`,
      )}
    >
      {pendingMethod && (
        <NewNotificationMethodSidebar
          onEvent={newMethodEventHandler}
          {...pendingMethod}
        />
      )}
    </div>
    <PageHeading icon="cog">Settings</PageHeading>
    <div className="flex flex-col lg:flex-row mt-8">
      <div className="p-8 bg-slate-100 rounded-xl flex-grow flex flex-col justify-end lg:mr-2 border border-slate-200 lg:max-w-3xl relative">
        <h2 className="text-lg text-slate-900 mb-2">Email address:</h2>
        <TextInput type="email" label="" value={email} disabled setValue={() => {}} />
        <Button
          type="link"
          to="/reset-password"
          color="tertiary"
          size="small"
          className="lg:absolute self-end mt-4 lg:mt-0 right-8 top-4"
        >
          Change password
        </Button>
      </div>
      <div
        className={cx(
          `p-8 bg-slate-100 rounded-xl lg:ml-8 lg:w-1/3 flex justify-between relative border border-slate-200 mt-4 lg:mt-0`,
          status.case === `trialing` && status.daysLeft < 10 && `pt-10`,
        )}
      >
        <div className="flex justify-end items-start flex-col mr-8">
          <h2 className="font-bold text-xl text-slate-700">Basic plan</h2>
          <h3 className="my-1">
            <span className="text-slate-600 font-medium text-lg relative bottom-3">
              $
            </span>
            <span className="text-slate-900 text-4xl font-bold">5</span>
            <span className="text-slate-600 text-lg font-medium">/month</span>
          </h3>
          {status.case !== `complimentary` && (
            <a
              {...(billingPortalRequest.state === `succeeded`
                ? { href: billingPortalRequest.payload.url }
                : {})}
              className={cx(
                `mt-2 text-sm whitespace-nowrap cursor-pointer transition-[color] duration-100`,
                manageSubscriptionStateClasses(billingPortalRequest),
              )}
              onClick={
                billingPortalRequest.state === `idle` ? manageSubscription : void 0
              }
            >
              {manageSubscriptionText(billingPortalRequest, status)}
            </a>
          )}
        </div>
        <AccountStatusBadge status={status} />
      </div>
    </div>
    <div className="mt-12 flex flex-col space-y-12">
      <div className="xs:bg-white xs:border border-slate-200 p-2 xs:p-8 rounded-3xl">
        <h2 className="text-2xl font-bold text-slate-800">Notification methods</h2>
        <p className="text-slate-500 mt-1">
          Verified ways that Gertrude can notify you for child requests
        </p>
        <ul className="mt-6">
          {methods.map((method) => (
            <NotificationMethod
              onDelete={() => deleteMethod.start(method.id)}
              key={method.id}
              {...method}
            />
          ))}
        </ul>
        <div className="mt-6 flex justify-start">
          <Button
            type="button"
            onClick={() => newMethodEventHandler({ type: `createClicked` })}
            color="secondary"
          >
            <i className="fa fa-plus mr-3" />
            Add method
          </Button>
        </div>
      </div>
      <div className="xs:bg-white xs:border border-slate-200 p-2 xs:p-8 rounded-3xl">
        <h2 className="text-2xl font-bold text-slate-800">Notifications</h2>
        <p className="text-slate-500 mt-1 mb-2">
          Custom notifications for different types of requests using one of your verified
          methods
        </p>
        {notifications.length > 0 ? (
          <div className="flex flex-wrap items-stretch pt-6 sm:pt-2 mb-6">
            {notifications.map(({ id, ...props }) => (
              <NotificationCard
                key={id}
                startEdit={() => updateNotification({ id, type: `startEditing` })}
                cancelEdit={() => updateNotification({ id, type: `cancelEditing` })}
                onDelete={() => deleteNotification.start(id)}
                updateMethod={(methodId) =>
                  updateNotification({ id, methodId, type: `changeMethod` })
                }
                updateTrigger={(trigger) =>
                  updateNotification({ id, trigger, type: `changeTrigger` })
                }
                onSave={() => saveNotification(id)}
                {...props}
              />
            ))}
          </div>
        ) : (
          <EmptyState
            heading={`No notifications`}
            secondaryText={`Get started by creating a custom notification`}
            icon={`bell`}
            buttonText={`Create notification`}
            action={createNotification}
            className="mt-6 bg-slate-50"
          />
        )}
        <div className="flex justify-center md:justify-start items-center pt-2">
          {notifications.length !== 0 && (
            <Button
              type="button"
              onClick={createNotification}
              color="primary"
              className="self-center"
              size="large"
            >
              <i className="fa fa-plus mr-3" />
              New notification
            </Button>
          )}
        </div>
      </div>
    </div>
  </div>
);

export default Settings;

const AccountStatusBadge: React.FC<{ status: AdminSubscriptionStatus }> = ({
  status,
}) => (
  <PillBadge
    type={statusType(status)}
    size="large"
    className="absolute right-2 top-2 border"
  >
    {statusText(status)}
  </PillBadge>
);

function statusType(
  status: AdminSubscriptionStatus,
): React.ComponentProps<typeof PillBadge>['type'] {
  switch (status.case) {
    case `complimentary`:
    case `paid`:
      return `ok`;
    case `trialing`:
      if (status.daysLeft < 10) {
        return `warning`;
      }
      return `ok`;
    case `overdue`:
      return `warning`;
    case `unpaid`:
      return `error`;
  }
}

function statusText(status: AdminSubscriptionStatus): string {
  switch (status.case) {
    case `complimentary`:
      return `complimentary`;
    case `trialing`:
      if (status.daysLeft === 1) {
        return `1 day left in trial`;
      }
      if (status.daysLeft < 10) {
        return `${status.daysLeft} days left in trial`;
      }
      return status.case;
    case `paid`:
      return `active`;
    case `overdue`:
      return `past due`;
    case `unpaid`:
      return `payment required`;
  }
}

function manageSubscriptionText(
  req: RequestState<unknown>,
  status: AdminSubscriptionStatus,
): string {
  switch (req.state) {
    case `idle`:
      switch (status.case) {
        case `complimentary`:
        case `trialing`:
          return `Start subscription...`;
        case `paid`:
          return `Manage subscription...`;
        case `overdue`:
        case `unpaid`:
          return `Resolve payment status...`;
      }
    case `ongoing`: // eslint-disable-line no-fallthrough
      return `Loading link...`;
    case `failed`:
      return `Failed to load`;
    case `succeeded`:
      return `Click here!`;
  }
}

function manageSubscriptionStateClasses(req: RequestState<unknown>): string {
  switch (req.state) {
    case `idle`:
      return `text-blue-700/80 hover:text-blue-800`;
    case `ongoing`:
      return `text-slate-500 animate-pulse`;
    case `failed`:
      return `text-red-700`;
    case `succeeded`:
      return `text-blue-800 hover:underline`;
  }
}
