import { prettyE164 } from '@shared/phone-numbers';
import cx from 'clsx';
import { MailIcon, MessageCircleIcon } from 'lucide-react';
import type { NotificationMethod } from '#/components/types';
import type React from 'react';

export function notificationMethodIcon(
  method: NotificationMethod,
  className = `h-4 w-4 shrink-0 text-stone-600`,
): React.ReactNode {
  switch (method.type) {
    case `email`:
      return <MailIcon className={className} />;
    case `text`:
      return <MessageCircleIcon className={className} />;
    case `slack`:
      return (
        <img src="/slack-logo.png" alt="" className={cx(className, `object-contain`)} />
      );
    case `ntfy`:
      return (
        <img src="/ntfy-logo.svg" alt="" className={cx(className, `rounded-[3px]`)} />
      );
  }
}

export function notificationMethodTypeLabel(method: NotificationMethod): string {
  switch (method.type) {
    case `email`:
      return `Email`;
    case `text`:
      return `Text`;
    case `slack`:
      return `Slack`;
    case `ntfy`:
      return `Ntfy`;
  }
}

export function notificationMethodTarget(method: NotificationMethod): string | null {
  switch (method.type) {
    case `email`:
      return method.emailAddress;
    case `text`:
      return prettyE164(method.phoneNumber);
    case `slack`:
      return `#${method.channelName.replace(/^#/, ``)}`;
    case `ntfy`:
      return truncateNtfyTopic(method.topicId);
  }
}

export function notificationMethodSelectLabel(method: NotificationMethod): string {
  const target = notificationMethodTarget(method);
  return target
    ? `${notificationMethodTypeLabel(method)} ${target}`
    : notificationMethodTypeLabel(method);
}

function truncateNtfyTopic(topic: string): string {
  return topic.length > 15 ? `${topic.slice(0, 12)}...` : topic;
}
