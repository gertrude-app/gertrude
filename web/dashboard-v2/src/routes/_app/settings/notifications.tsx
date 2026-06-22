import { Button } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import { BellDotIcon, MailIcon, MessageCircleIcon, PlusIcon, XIcon } from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/CardContainer';
import AddNotificationMethodSlideOver from '#/components/settings/AddNotificationMethodSlideOver';
import {
  type NotificationMethod,
  getNotificationSettingsPage,
  useMockDataSelector,
} from '#/lib/mock';

function methodLabel(method: NotificationMethod): React.ReactNode {
  const baseClasses = `text-stone-600 ml-2.5`;
  const targetClasses = `font-medium text-stone-900 bg-stone-100 px-1 py-0.25 rounded border-[0.5px] border-stone-300`;

  switch (method.type) {
    case `email`:
      return (
        <span className={baseClasses}>
          Email <span className={targetClasses}>{method.emailAddress}</span>
        </span>
      );
    case `text`:
      return (
        <span className={baseClasses}>
          Text <span className={targetClasses}>{method.phoneNumber}</span>
        </span>
      );
    case `slack`:
      return (
        <span className={baseClasses}>
          Slack <span className={targetClasses}>#{method.channelName}</span>
        </span>
      );
    case `ntfy`:
      return (
        <span className={baseClasses}>
          Notify <span className={targetClasses}>{method.topicId}</span> via ntfy
        </span>
      );
    case `push`:
      return <span className={baseClasses}>Push</span>;
  }
}

function methodIcon(method: NotificationMethod): React.ReactNode {
  const iconClasses = `h-4 w-4 text-stone-600 shrink-0`;

  switch (method.type) {
    case `email`:
      return <MailIcon className={iconClasses} />;
    case `text`:
      return <MessageCircleIcon className={iconClasses} />;
    case `slack`:
      return <img src="/slack-logo.png" alt="" className="w-4 h-4 shrink-0" />;
    case `ntfy`:
      return <img src="/ntfy-logo.svg" alt="" className="w-4.5 h-4.5 shrink-0 rounded" />;
    case `push`:
      return <BellDotIcon className={iconClasses} />;
  }
}

const NotificationSettingsPage: React.FC = () => {
  const [addMethodOpen, setAddMethodOpen] = React.useState(false);
  const { notificationMethods, notifications } = useMockDataSelector(
    getNotificationSettingsPage,
  );

  return (
    <>
      <div className="flex flex-col gap-4 mt-4">
        <CardContainer
          heading="Methods"
          subheading="Verified ways that Gertrude can notify you for child requests and events."
          buttons={[
            <Button type="button" onClick={() => setAddMethodOpen(true)} icon={PlusIcon}>
              Add Method
            </Button>,
          ]}
        >
          <div className="flex flex-wrap gap-2 mt-4">
            {notificationMethods.map((method) => (
              <div
                key={method.id}
                className="bg-white border border-stone-200 rounded-xl shadow shadow-stone-300/30 p-1.5 pl-3 flex items-center"
              >
                {methodIcon(method)}
                {methodLabel(method)}
                <Button
                  type="button"
                  onClick={() => {}}
                  size="small"
                  variant="ghost"
                  icon={XIcon}
                  className="ml-2"
                />
              </div>
            ))}
          </div>
        </CardContainer>
        <CardContainer
          heading="Notifications"
          subheading="Custom notifications for different types of events using one of your verified methods."
          buttons={[
            <Button type="button" onClick={() => {}}>
              Add Notification
            </Button>,
          ]}
        >
          <div className="mt-4 text-sm text-stone-500">
            {notifications.length} mock notifications ready
          </div>
        </CardContainer>
      </div>
      <AddNotificationMethodSlideOver
        open={addMethodOpen}
        onOpenChange={setAddMethodOpen}
      />
    </>
  );
};

export const Route = createFileRoute(`/_app/settings/notifications`)({
  component: NotificationSettingsPage,
});
