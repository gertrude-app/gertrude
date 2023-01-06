import React from 'react';
import cx from 'classnames';
import { TextInput, Button } from '@shared/components';
import { isUnsaved } from '@dash/utils';
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
import PillBadge from '../PillBadge';
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
  billingPortalRequest: RequestState<string>;
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

const Profile: React.FC<Props> = ({
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
  <div className="lg:px-4 relative">
    <ConfirmDeleteEntity type="notification" action={deleteNotification} />
    <ConfirmDeleteEntity type="notification method" action={deleteMethod} />
    <div
      className={cx(
        `absolute left-0 top-0 w-full h-full z-20 bg-gray-50 bg-opacity-60`,
        pendingMethod ? `block` : `hidden`,
      )}
    />
    <div
      className={cx(
        `fixed bg-white top-0 right-0 w-76 md:w-96 h-screen border-l shadow-xl [transition:150ms] z-30 flex flex-col justify-beween`,
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
    <PageHeading icon="user">Profile</PageHeading>
    <div className="flex flex-col lg:flex-row mt-8">
      <div className="p-8 bg-gray-100 rounded-xl flex-grow lg:mr-2 border max-w-3xl">
        <h2 className="text-lg text-gray-900 mb-2">Email address:</h2>
        <TextInput type="email" label="" value={email} disabled setValue={() => {}} />
      </div>
      <div className="px-8 py-4 bg-gray-100 rounded-xl lg:ml-2 lg:w-1/3 flex justify-between relative border mt-4 lg:mt-0">
        <div className="flex justify-end items-start flex-col mr-8">
          <h2 className="font-bold text-gray-700">Basic plan</h2>
          <h3>
            <span className="text-gray-600">$</span>
            <span className="text-gray-700 text-3xl font-bold">10</span>
            <span className="text-gray-600 text-lg">/month</span>
          </h3>
          {status !== `complimentary` && (
            <a
              {...(billingPortalRequest.state === `succeeded`
                ? { href: billingPortalRequest.payload, target: `_blank` }
                : {})}
              className={cx(
                `mt-1 text-sm whitespace-nowrap cursor-pointer transition duration-100`,
                manageSubscriptionStateClasses(billingPortalRequest),
              )}
              onClick={
                billingPortalRequest.state === `idle` ? manageSubscription : void 0
              }
            >
              {manageSubscriptionText(billingPortalRequest)}
            </a>
          )}
        </div>
        <AccountStatusBadge status={status} />
      </div>
    </div>
    <div className="mt-16">
      <div className="flex flex-col">
        <div className="mb-16">
          <h2 className="text-2xl font-bold text-gray-800">Notification methods</h2>
          <p className="text-gray-500 mt-1">
            Verified ways that Gertrude can notify you for user requests
          </p>
          <ul className="mt-5">
            {methods.map((method) => (
              <NotificationMethod
                onDelete={() => deleteMethod.start(method.id)}
                key={method.id}
                {...method}
              />
            ))}
          </ul>
          <Button
            type="button"
            onClick={() => newMethodEventHandler({ type: `create_clicked` })}
            color="secondary"
            small
            className="mt-4"
          >
            <i className="fa fa-plus mr-3" />
            Add method
          </Button>
        </div>
        <div>
          <h2 className="text-2xl font-bold text-gray-800">Notifications</h2>
          <p className="text-gray-500 mt-1">
            Custom notifications for different types of requests using one of your
            verified methods
          </p>
          {notifications.length > 0 ? (
            <div className="flex flex-wrap items-start pt-4 sm:pt-2 mb-4">
              {notifications.map(({ id, ...props }) => (
                <NotificationCard
                  key={id}
                  focus={isUnsaved(id)}
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
              className="mt-6"
            />
          )}
        </div>
        {notifications.length !== 0 && (
          <Button
            type="button"
            onClick={createNotification}
            color="primary"
            className="self-center"
          >
            <i className="fa fa-plus mr-3" />
            New notification
          </Button>
        )}
      </div>
    </div>
  </div>
);

export default Profile;

const AccountStatusBadge: React.FC<{ status: AdminSubscriptionStatus }> = ({
  status,
}) => (
  <PillBadge type={statusType(status)} className="absolute right-2 top-2">
    {statusText(status)}
  </PillBadge>
);

function statusType(
  status: AdminSubscriptionStatus,
): React.ComponentProps<typeof PillBadge>['type'] {
  switch (status) {
    case `active`:
    case `complimentary`:
    case `emailVerified`:
    case `pendingEmailVerification`:
    case `trialing`:
      return `ok`;
    case `incomplete`:
    case `incompleteExpired`:
    case `pastDue`:
      return `warning`;
    case `canceled`:
    case `signupCanceled`:
    case `unpaid`:
    default:
      return `error`;
  }
}

function statusText(status: AdminSubscriptionStatus): string {
  switch (status) {
    case `active`:
    case `canceled`:
    case `complimentary`:
    case `incomplete`:
    case `trialing`:
    case `unpaid`:
      return status;
    case `incompleteExpired`:
      return `incomplete`;
    case `emailVerified`:
      return `email verified`;
    case `pastDue`:
      return `past due`;
    case `pendingEmailVerification`:
      return `pending email verification`;
    case `signupCanceled`:
      return `signup canceled`;
    default:
      return status;
  }
}

function manageSubscriptionText(req: RequestState<unknown>): string {
  switch (req.state) {
    case `idle`:
      return `Manage subscription...`;
    case `ongoing`:
      return `Loading...`;
    case `failed`:
      return `Failed to load`;
    case `succeeded`:
      return `Click here`;
  }
}

function manageSubscriptionStateClasses(req: RequestState<unknown>): string {
  switch (req.state) {
    case `idle`:
      return `text-blue-700/80 hover:text-blue-800`;
    case `ongoing`:
      return `text-gray-500 animate-pulse`;
    case `failed`:
      return `text-red-700`;
    case `succeeded`:
      return `text-blue-800 hover:underline`;
  }
}
