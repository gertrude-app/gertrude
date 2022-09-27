import React from 'react';
import cx from 'classnames';
import Button from '../../Button';
import { Link } from 'react-router-dom';
import PageHeading from '../../dashboard/PageHeading';
import PillBadge from '../../dashboard/PillBadge';
import NewNotificationMethodSidebar from './NewNotificationMethodForm';
import NotificationCard from './NotificationCard';
import TextInput from '../../dashboard/TextInput';
import NotificationMethod from './NotificationMethod';
import { ConfirmableEntityAction, SubcomponentsOmit } from '../../types';
import { ConfirmDeleteEntity } from '../Modal';
import { Trigger } from '../types/GraphQL';
import { isUnsaved } from '../lib/id';
import {
  PendingNotificationMethod,
  NewAdminNotificationMethodEvent,
} from '../types/Admin';

export type NotificationUpdate = { id: UUID } & (
  | { type: 'startEditing' }
  | { type: 'cancelEditing' }
  | { type: 'changeTrigger'; trigger: Trigger }
  | { type: 'changeMethod'; methodId: UUID }
);

interface Props {
  email: string;
  status: string; // @TODO: enum
  pendingMethod?: PendingNotificationMethod;
  methods: SubcomponentsOmit<typeof NotificationMethod, 'onDelete'>;
  notifications: SubcomponentsOmit<
    typeof NotificationCard,
    'onDelete' | 'cancelEdit' | 'startEdit' | 'updateMethod' | 'updateTrigger' | 'onSave'
  >;
  deleteNotification: ConfirmableEntityAction;
  deleteMethod: ConfirmableEntityAction;
  updateNotification(update: NotificationUpdate): unknown;
  saveNotification(id: UUID): unknown;
  createNotification(): unknown;
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
        <TextInput type="email" label="" value={email} setValue={() => {}} />
      </div>
      <div className="px-8 py-4 bg-gray-100 rounded-xl lg:ml-2 flex justify-between relative border mt-4 lg:mt-0">
        <div className="flex justify-end items-start flex-col mr-8">
          <h2 className="font-bold text-gray-700">Basic plan</h2>
          <h3>
            <span className="text-gray-600">$</span>
            <span className="text-gray-700 text-3xl font-bold">10</span>
            <span className="text-gray-600 text-lg">/month</span>
          </h3>
          <Link
            className="mt-1 text-sm text-blue-700 hover:text-blue-800 cursor-pointer transition duration-100"
            to="/profile"
          >
            Manage subscription
          </Link>
        </div>
        <PillBadge type="ok" className="absolute right-2 top-2">
          {status}
        </PillBadge>
      </div>
    </div>
    <div className="mt-12">
      <div className="flex flex-col">
        <div className="mb-10">
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
            color="secondary-white"
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
        </div>
        <Button
          type="button"
          onClick={createNotification}
          color="primary-violet"
          className="self-center"
        >
          <i className="fa fa-plus mr-3" />
          New notification
        </Button>
      </div>
    </div>
  </div>
);

export default Profile;
