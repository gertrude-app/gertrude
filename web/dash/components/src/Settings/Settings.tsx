import { Button, TextInput } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import type {
  AdminNotificationTrigger,
  ConfirmableEntityAction,
  GetSubscriptionPanel_v2,
  NewAdminNotificationMethodEvent,
  PendingNotificationMethod,
  Subcomponents,
  SubscriptionPanelAction,
} from '@dash/types';
import EmptyState from '../EmptyState';
import Modal, { ConfirmDeleteEntity } from '../Modal';
import PageHeading from '../PageHeading';
import NewNotificationMethodSidebar from './NewNotificationMethodForm';
import NotificationCard from './NotificationCard';
import NotificationMethod from './NotificationMethod';
import SubscriptionPanel from './SubscriptionPanel';

export type NotificationUpdate = { id: UUID } & (
  | { type: `startEditing` }
  | { type: `cancelEditing` }
  | { type: `changeTrigger`; trigger: AdminNotificationTrigger }
  | { type: `changeMethod`; methodId: UUID }
);

export type NewMethod = { id: UUID; confirmed: boolean };

interface Props {
  email: string;
  subscriptionPanel: GetSubscriptionPanel_v2.Output;
  onSubscriptionPanelAction(action: SubscriptionPanelAction): unknown;
  pendingSubscriptionPanelAction?: SubscriptionPanelAction;
  pendingMethod?: PendingNotificationMethod;
  methods: Subcomponents<typeof NotificationMethod>;
  notifications: Subcomponents<typeof NotificationCard>;
  deleteNotification: ConfirmableEntityAction;
  deleteMethod: ConfirmableEntityAction;
  updateNotification(update: NotificationUpdate): unknown;
  saveNotification(id: UUID): unknown;
  createNotification(methodId?: string): unknown;
  newMethodEventHandler(event: NewAdminNotificationMethodEvent): unknown;
  newMethodId?: NewMethod;
  setNewMethodId(id: NewMethod | undefined): unknown;
}

const Settings: React.FC<Props> = ({
  email,
  subscriptionPanel,
  onSubscriptionPanelAction,
  pendingSubscriptionPanelAction,
  methods,
  notifications,
  updateNotification,
  saveNotification,
  deleteNotification,
  createNotification,
  deleteMethod,
  pendingMethod,
  newMethodEventHandler,
  newMethodId,
  setNewMethodId,
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
      <div className="p-8 bg-slate-100 rounded-xl flex-grow flex flex-col lg:mr-2 border border-slate-200 lg:max-w-3xl relative">
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
      <SubscriptionPanel
        {...subscriptionPanel}
        onAction={onSubscriptionPanelAction}
        pendingAction={pendingSubscriptionPanelAction}
        className="lg:ml-8 lg:w-1/3 mt-4 lg:mt-0"
      />
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
