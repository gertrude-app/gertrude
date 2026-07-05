import type { NotificationTrigger } from '#/components/types';

export type NotificationTriggerCategory =
  `suspendFilterRequestSubmitted` | `unlockRequestSubmitted` | `securityEvents`;
export type SecurityEventLevel = `recommended` | `medium` | `all`;

export function notificationTriggerText(trigger: NotificationTrigger): string {
  switch (trigger) {
    case `suspendFilterRequestSubmitted`:
      return `filter suspension requests`;
    case `unlockRequestSubmitted`:
      return `unlock requests`;
    case `securityEventsAll`:
      return `all security events`;
    case `securityEventsMedium`:
      return `security events`;
    case `securityEventsRecommended`:
      return `high-risk security events`;
  }
}

export function getNotificationTriggerCategory(
  trigger: NotificationTrigger,
): NotificationTriggerCategory {
  switch (trigger) {
    case `suspendFilterRequestSubmitted`:
    case `unlockRequestSubmitted`:
      return trigger;
    case `securityEventsRecommended`:
    case `securityEventsMedium`:
    case `securityEventsAll`:
      return `securityEvents`;
  }
}

export function getSecurityLevel(
  trigger: NotificationTrigger,
): SecurityEventLevel | null {
  switch (trigger) {
    case `securityEventsRecommended`:
      return `recommended`;
    case `securityEventsMedium`:
      return `medium`;
    case `securityEventsAll`:
      return `all`;
    case `suspendFilterRequestSubmitted`:
    case `unlockRequestSubmitted`:
      return null;
  }
}

export function notificationTriggerFromSecurityLevel(
  level: SecurityEventLevel,
): NotificationTrigger {
  switch (level) {
    case `recommended`:
      return `securityEventsRecommended`;
    case `medium`:
      return `securityEventsMedium`;
    case `all`:
      return `securityEventsAll`;
  }
}
