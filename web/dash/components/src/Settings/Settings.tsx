import { Badge, Button, TextInput } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import type {
  AdminNotificationTrigger,
  ConfirmableEntityAction,
  NewAdminNotificationMethodEvent,
  PendingNotificationMethod,
  Plan,
  RequestState,
  Subcomponents,
} from '@dash/types';
import EmptyState from '../EmptyState';
import Modal, { ConfirmDeleteEntity } from '../Modal';
import PageHeading from '../PageHeading';
import NewNotificationMethodSidebar from './NewNotificationMethodForm';
import NotificationCard from './NotificationCard';
import NotificationMethod from './NotificationMethod';

export type NotificationUpdate = { id: UUID } & (
  | { type: `startEditing` }
  | { type: `cancelEditing` }
  | { type: `changeTrigger`; trigger: AdminNotificationTrigger }
  | { type: `changeMethod`; methodId: UUID }
);

export type NewMethod = { id: UUID; confirmed: boolean };

interface Props {
  email: string;
  plan: Plan;
  billingPortalRequest: RequestState<{ url: string }>;
  pendingMethod?: PendingNotificationMethod;
  methods: Subcomponents<typeof NotificationMethod>;
  notifications: Subcomponents<typeof NotificationCard>;
  deleteNotification: ConfirmableEntityAction;
  deleteMethod: ConfirmableEntityAction;
  updateNotification(update: NotificationUpdate): unknown;
  saveNotification(id: UUID): unknown;
  createNotification(methodId?: string): unknown;
  manageSubscription(): unknown;
  newMethodEventHandler(event: NewAdminNotificationMethodEvent): unknown;
  newMethodId?: NewMethod;
  setNewMethodId(id: NewMethod | undefined): unknown;
  requestedTier?: `full` | `light` | null;
}

const Settings: React.FC<Props> = ({
  email,
  plan,
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
  newMethodId,
  setNewMethodId,
  requestedTier,
}) => (
  <div className="relative">
    {newMethodId && newMethodId.confirmed && (
      <Modal
        title="One more step!"
        icon="bell"
        primaryButton={{
          type: `action`,
          action: () => {
            createNotification(newMethodId.id);
            setNewMethodId(undefined);
          },
          label: (
            <div>
              <i className="fa fa-plus mr-3" />
              <span>Create notification</span>
            </div>
          ),
        }}
        onDismiss={() => setNewMethodId(undefined)}
      >
        Now that you’ve confirmed this communication <b>method</b>, you’ll need to create
        a <b>notification</b> that uses it.
      </Modal>
    )}
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
        `fixed bg-white top-0 right-0 w-76 md:w-96 h-full border-l rounded-l-xl border-slate-200 shadow-xl transition-[margin-right] z-30 flex flex-col justify-beween`,
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
          shouldShowTrialWarning(plan) && `pt-10`,
        )}
      >
        <div className="flex justify-end items-start flex-col mr-8">
          <h2 className="font-bold text-xl text-slate-700">{planName(plan)}</h2>
          <PlanPrice plan={plan} />
          {showManageSubscriptionLink(plan, requestedTier) && (
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
              {manageSubscriptionText(billingPortalRequest, plan, requestedTier)}
            </a>
          )}
        </div>
        <AccountStatusBadge plan={plan} />
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
              createNotification={() => createNotification(method.id)}
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
          Custom notifications for different types of events using one of your verified
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

const AccountStatusBadge: React.FC<{ plan: Plan }> = ({ plan }) => (
  <Badge type={badgeType(plan)} size="large" className="absolute right-2 top-2 border">
    {badgeText(plan)}
  </Badge>
);

const PlanPrice: React.FC<{ plan: Plan }> = ({ plan }) => {
  const price = priceInfo(plan);
  if (!price) return null;
  return (
    <h3 className="my-1">
      <span className="text-slate-600 font-medium text-lg relative bottom-3">$</span>
      <span className="text-slate-900 text-4xl font-bold">{price.dollars}</span>
      <span className="text-slate-600 text-lg font-medium">/{price.interval}</span>
    </h3>
  );
};

function planName(plan: Plan): string {
  switch (plan.case) {
    case `free`:
      return `Free plan`;
    case `light`:
      return `Light plan`;
    case `full`:
      return `Full plan`;
  }
}

function priceInfo(plan: Plan): { dollars: number; interval: string } | null {
  switch (plan.case) {
    case `free`:
      return { dollars: 0, interval: `month` };
    case `light`:
      return { dollars: 10, interval: `year` };
    case `full`:
      switch (plan.status.case) {
        case `trialing`:
        case `trialExpired`:
        case `complimentary`:
          return { dollars: 10, interval: `month` };
        case `paid`:
        case `overdue`:
          return { dollars: plan.status.monthlyPriceInCents / 100, interval: `month` };
      }
  }
}

function shouldShowTrialWarning(plan: Plan): boolean {
  if (plan.case !== `full`) return false;
  if (plan.status.case === `trialExpired`) return true;
  if (plan.status.case !== `trialing`) return false;
  const daysLeft = trialDaysRemaining(plan.status.until);
  return daysLeft < 10;
}

function trialDaysRemaining(until: string): number {
  const now = new Date();
  const end = new Date(until);
  const diff = end.getTime() - now.getTime();
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
}

function showManageSubscriptionLink(
  plan: Plan,
  requestedTier?: `full` | `light` | null,
): boolean {
  if (plan.case === `free`) {
    if (requestedTier) return true;
    if (plan.kind.case === `lapsedFull` || plan.kind.case === `lapsedLight`) return true;
    return false;
  }
  if (plan.case === `full` && plan.status.case === `complimentary`) return false;
  return true;
}

function badgeType(plan: Plan): React.ComponentProps<typeof Badge>[`type`] {
  switch (plan.case) {
    case `free`:
      return `ok`;
    case `light`:
      return plan.status.case === `overdue` ? `warning` : `ok`;
    case `full`:
      switch (plan.status.case) {
        case `complimentary`:
        case `paid`:
          return `ok`;
        case `trialing`: {
          const daysLeft = trialDaysRemaining(plan.status.until);
          return daysLeft < 10 ? `warning` : `ok`;
        }
        case `trialExpired`:
        case `overdue`:
          return `warning`;
      }
  }
}

function badgeText(plan: Plan): string {
  switch (plan.case) {
    case `free`:
      return `free`;
    case `light`:
      return plan.status.case === `overdue` ? `past due` : `active`;
    case `full`:
      switch (plan.status.case) {
        case `complimentary`:
          return `complimentary`;
        case `trialing`: {
          const daysLeft = trialDaysRemaining(plan.status.until);
          if (daysLeft === 1) return `1 day left in trial`;
          if (daysLeft < 10) return `${daysLeft} days left in trial`;
          return `trialing`;
        }
        case `trialExpired`:
          return `trial expired`;
        case `paid`:
          return `active`;
        case `overdue`:
          return `past due`;
      }
  }
}

function manageSubscriptionText(
  req: RequestState<unknown>,
  plan: Plan,
  requestedTier?: `full` | `light` | null,
): string {
  switch (req.state) {
    case `idle`:
      if (requestedTier === `full`) {
        return `Subscribe to Full ($10/month)...`;
      }
      if (
        plan.case === `full` &&
        (plan.status.case === `trialing` || plan.status.case === `trialExpired`)
      ) {
        return `Start subscription...`;
      }
      if (
        (plan.case === `light` && plan.status.case === `overdue`) ||
        (plan.case === `full` && plan.status.case === `overdue`)
      ) {
        return `Resolve payment status...`;
      }
      if (plan.case === `free`) {
        switch (plan.kind.case) {
          case `lapsedLight`:
            return `Reactivate subscription...`;
          case `lapsedFull`:
            return plan.kind.stripeId
              ? `Reactivate subscription...`
              : `Start subscription...`;
          case `standard`:
            return `Upgrade plan...`;
        }
      }
      return `Manage subscription...`;
    case `ongoing`:
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
