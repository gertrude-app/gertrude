// auto-generated, do not edit
export type { ServerPqlError } from '../PqlError';

export interface AccountNotification {
  id: UUID;
  trigger: NotificationTrigger;
  methodId: UUID;
}

export interface AccountNotificationMethod {
  id: UUID;
  config: NotificationMethodConfig;
}

export type AppScope =
  | { type: 'unrestricted' }
  | { type: 'webBrowsers' }
  | { type: 'single'; single: SingleAppScope };

export type BillingStatus =
  | { case: 'current'; renewsAt: ISODateString }
  | { case: 'pastDue'; since: ISODateString };

export type BlockRule =
  | { case: 'bundleIdContains'; value: string }
  | { case: 'urlContains'; value: string }
  | { case: 'hostnameContains'; value: string }
  | { case: 'hostnameEquals'; value: string }
  | { case: 'hostnameEndsWith'; value: string }
  | { case: 'hostnameOrSubdomain'; value: string }
  | { case: 'targetContains'; value: string }
  | { case: 'flowTypeIs'; value: 'browser' | 'socket' }
  | { case: 'both'; a: BlockRule; b: BlockRule }
  | { case: 'unless'; rule: BlockRule; negatedBy: BlockRule[] };

export type ClientAuth = 'none' | 'child' | 'parent' | 'superAdmin';

export type NotificationMethodConfig =
  | { case: 'slack'; channelId: string; channelName: string; token: string }
  | { case: 'email'; email: string }
  | { case: 'text'; phoneNumber: string }
  | { case: 'ntfy'; topic: string };

export type NotificationTrigger =
  | 'unlockRequestSubmitted'
  | 'suspendFilterRequestSubmitted'
  | 'securityEventsAll'
  | 'securityEventsMedium'
  | 'securityEventsRecommended';

export type PersonRelationship = 'child' | 'peer' | 'self';

export type PlanStatus =
  | {
      case: 'light';
      status:
        | { case: 'current'; renewsAt: ISODateString }
        | { case: 'pastDue'; since: ISODateString };
    }
  | {
      case: 'medium';
      status:
        | { case: 'current'; renewsAt: ISODateString }
        | { case: 'pastDue'; since: ISODateString };
    }
  | {
      case: 'full';
      status:
        | { case: 'current'; renewsAt: ISODateString }
        | { case: 'pastDue'; since: ISODateString };
    }
  | {
      case: 'fullTrial';
      until: ISODateString;
      substrate?: {
        tier: 'light' | 'medium' | 'full';
        status:
          | { case: 'current'; renewsAt: ISODateString }
          | { case: 'pastDue'; since: ISODateString };
      };
    }
  | {
      case: 'fullTrialGrace';
      until: ISODateString;
      substrate?: {
        tier: 'light' | 'medium' | 'full';
        status:
          | { case: 'current'; renewsAt: ISODateString }
          | { case: 'pastDue'; since: ISODateString };
      };
    }
  | { case: 'free' }
  | { case: 'complimentary' };

export type SharedKey =
  | { type: 'anySubdomain'; domain: string; scope: AppScope }
  | { type: 'domain'; domain: string; scope: AppScope }
  | { type: 'domainRegex'; pattern: string; scope: AppScope }
  | { type: 'skeleton'; scope: SingleAppScope }
  | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
  | { type: 'path'; path: string; scope: AppScope };

export type SingleAppScope =
  | { type: 'bundleId'; bundleId: string }
  | { type: 'identifiedAppSlug'; identifiedAppSlug: string };

export type SubscriptionPanelAction =
  | { case: 'startCheckout'; tier: SubscriptionTier }
  | { case: 'openBillingPortal'; config: 'lightTier' | 'mediumTier' | 'default' }
  | { case: 'changeSubscriptionTier'; to: SubscriptionTier }
  | { case: 'reactivateViaCheckout'; tier: SubscriptionTier }
  | { case: 'startFullTrial' };

export type SubscriptionTier = 'light' | 'medium' | 'full';

export interface SuccessOutput {
  success: boolean;
}
