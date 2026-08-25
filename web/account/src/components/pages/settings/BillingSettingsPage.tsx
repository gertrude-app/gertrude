import {
  Badge,
  Button,
  Card,
  ConfirmationDialog,
  HStack,
  Text,
  VStack,
} from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon } from 'lucide-react';
import React from 'react';
import type {
  GetAccountBilling,
  SubscriptionPanelAction,
} from '@shared/pairql/src/account';
import CardContainer from '#/components/layout/CardContainer';
import {
  type CurrentPlan,
  PLAN_FEATURES,
  actionKey,
  actionLabel,
  actionsByPlan,
  currentPlan,
  planBadge,
  planCardBadge,
  planOverview,
  planTitle,
} from '#/lib/billing';

interface Props {
  billing: GetAccountBilling.Output;
  pendingAction?: SubscriptionPanelAction;
  onAction: (action: SubscriptionPanelAction) => void | Promise<void>;
}

const PLAN_TIERS = Object.keys(PLAN_FEATURES) as CurrentPlan[];

const BillingSettingsPage: React.FC<Props> = ({ billing, pendingAction, onAction }) => {
  const statusBadge = planBadge(billing);
  const selectedPlan = currentPlan(billing.planStatus);
  const groupedActions = actionsByPlan(billing);
  const pendingActionKey = pendingAction ? actionKey(pendingAction) : undefined;
  const primaryActionKey = billing.primary ? actionKey(billing.primary) : undefined;

  return (
    <VStack gap={4} className="mt-4">
      <VStack gap={1} className="py-2">
        <HStack gap={2} align="center" wrap>
          <Text as="h2" variant="title">
            {planTitle(billing)}
          </Text>
          <Badge color={statusBadge.color}>{statusBadge.text}</Badge>
        </HStack>
        {planOverview(billing).map((line) => (
          <Text as="p" variant="bodyMuted" key={line} className="max-w-4xl">
            {line}
          </Text>
        ))}
      </VStack>

      <CardContainer
        heading="Plans"
        subheading="Each plan includes everything from the plans before it."
      >
        <div className="mt-4 grid items-stretch gap-3 @2xl/main:grid-cols-2 @5xl/main:grid-cols-4">
          {PLAN_TIERS.map((tier) => {
            const plan = PLAN_FEATURES[tier];
            const selected = tier === selectedPlan;
            const badge = planCardBadge(billing, tier);
            const actions = groupedActions[tier];
            const footnote = planFootnote(billing, tier, selected, badge?.text);

            return (
              <Card
                key={tier}
                padding={0}
                className={cx(
                  `flex h-full flex-col`,
                  selected &&
                    `border-violet-400 bg-violet-50/50 shadow-lg shadow-violet-200/40 ring-1 ring-violet-300`,
                )}
              >
                <div className="flex flex-1 flex-col p-4">
                  <HStack justify="between" align="start" gap={2}>
                    <VStack gap={0.5}>
                      <Text as="h3" variant="bodyLargeStrong">
                        {plan.name}
                      </Text>
                      <div className="flex items-baseline gap-1.5">
                        <span className="text-2xl font-semibold tracking-tight text-stone-950">
                          {plan.price}
                        </span>
                        {plan.cadence && (
                          <span className="text-sm text-stone-500">{plan.cadence}</span>
                        )}
                      </div>
                      {plan.billingNote && (
                        <Text variant="captionMuted">{plan.billingNote}</Text>
                      )}
                    </VStack>
                    {badge && (
                      <Badge color={badge.color} size="small">
                        {badge.text}
                      </Badge>
                    )}
                  </HStack>

                  <VStack as="ul" gap={2} className="mt-4 flex-1">
                    {plan.features.map((feature) => (
                      <HStack as="li" key={feature} align="start" gap={2}>
                        <CheckIcon className="mt-0.5 h-4 w-4 shrink-0 text-violet-600" />
                        <Text variant="bodyMuted">{feature}</Text>
                      </HStack>
                    ))}
                  </VStack>

                  {(actions.length > 0 || footnote) && (
                    <div className="mt-5 border-t border-stone-200/80 pt-4">
                      {actions.length > 0 ? (
                        <VStack gap={2}>
                          {actions.map((action) => {
                            const key = actionKey(action);
                            const label = actionLabel(action, billing);
                            const button = (
                              <Button
                                key={key}
                                type="button"
                                variant={key === primaryActionKey ? `primary` : `default`}
                                className="w-full justify-center"
                                disabled={pendingAction !== undefined}
                                loading={key === pendingActionKey}
                                onClick={() => {
                                  if (action.case !== `startFullTrial`) {
                                    void onAction(action);
                                  }
                                }}
                              >
                                {label}
                              </Button>
                            );

                            if (action.case === `startFullTrial`) {
                              return (
                                <ConfirmationDialog
                                  key={key}
                                  confirmationQuestion="Start your 21-day Full trial?"
                                  description="Your trial starts immediately and is available once per account. No credit card is required, and you won’t be charged when it ends."
                                  trigger={button}
                                  actions={[
                                    { text: `Cancel`, variant: `ghost` },
                                    {
                                      text: `Start free trial`,
                                      variant: `primary`,
                                      onClick: () => onAction(action),
                                    },
                                  ]}
                                />
                              );
                            }

                            return button;
                          })}
                        </VStack>
                      ) : (
                        <Text as="p" variant="captionMuted">
                          {footnote}
                        </Text>
                      )}
                    </div>
                  )}
                </div>
              </Card>
            );
          })}
        </div>
      </CardContainer>
    </VStack>
  );
};

export default BillingSettingsPage;

function planFootnote(
  billing: GetAccountBilling.Output,
  tier: CurrentPlan,
  selected: boolean,
  badgeText: string | undefined,
): string | undefined {
  if (selected && billing.planStatus.case === `complimentary`) {
    return `Complimentary access is active.`;
  }
  if (selected) {
    return `This is your current plan.`;
  }
  if (badgeText === `Paid base plan`) {
    return `This subscription continues underneath your Full trial.`;
  }
  if (badgeText === `Past-due base plan`) {
    return `Update its payment method to restore the underlying subscription.`;
  }
  if (tier === `free`) {
    return `Included with every Gertrude account.`;
  }
  return undefined;
}
