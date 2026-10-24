import {
  Badge,
  Button,
  Card,
  ConfirmationDialog,
  HStack,
  Modal,
  Text,
  VStack,
} from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon } from 'lucide-react';
import React from 'react';
import type {
  GetAccountBilling,
  SubscriptionPanelAction,
  SubscriptionTier,
} from '@shared/pairql/src/account';
import PlanChangeSummary from '#/components/billing/PlanChangeSummary';
import CardContainer from '#/components/layout/CardContainer';
import {
  type CurrentPlan,
  actionKey,
  actionLabel,
  actionsByPlan,
  currentPlan,
  planBadge,
  planCardBadge,
  planOverview,
  planTitle,
} from '#/lib/billing';
import { FEATURES, PLANS, PLAN_IDS, planPriceDisplay } from '#/lib/plans';

interface Props {
  billing: GetAccountBilling.Output;
  pendingAction?: SubscriptionPanelAction;
  returnHref?: string;
  onAction: (action: SubscriptionPanelAction) => void | Promise<void>;
}

const BillingSettingsPage: React.FC<Props> = ({
  billing,
  pendingAction,
  returnHref,
  onAction,
}) => {
  const [planChange, setPlanChange] =
    React.useState<
      Extract<SubscriptionPanelAction, { case: `changeSubscriptionTier` }>
    >();
  const statusBadge = planBadge(billing);
  const selectedPlan = currentPlan(billing.planStatus);
  const groupedActions = actionsByPlan(billing);
  const pendingActionKey = pendingAction ? actionKey(pendingAction) : undefined;
  const primaryActionKey = billing.primary ? actionKey(billing.primary) : undefined;

  return (
    <>
      {returnHref && (
        <a
          href={returnHref}
          className="mx-4 mt-4 inline-block text-sm font-medium text-violet-700 underline"
        >
          Continue device setup
        </a>
      )}
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
            {PLAN_IDS.map((tier) => {
              const plan = PLANS[tier];
              const price = planPriceDisplay(plan.price);
              const features = [
                ...(plan.includes ? [`Everything in ${PLANS[plan.includes].name}`] : []),
                ...plan.features.map((feature) => FEATURES[feature]),
              ];
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
                            {price.amount}
                          </span>
                          {price.cadence && (
                            <span className="text-sm text-stone-500">
                              {price.cadence}
                            </span>
                          )}
                        </div>
                        {price.billingNote && (
                          <Text variant="captionMuted">{price.billingNote}</Text>
                        )}
                      </VStack>
                      {badge && (
                        <Badge color={badge.color} size="small">
                          {badge.text}
                        </Badge>
                      )}
                    </HStack>

                    <VStack as="ul" gap={2} className="mt-4 flex-1">
                      {features.map((feature) => (
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
                                  variant={
                                    key === primaryActionKey ? `primary` : `default`
                                  }
                                  className="w-full justify-center"
                                  disabled={pendingAction !== undefined}
                                  loading={key === pendingActionKey}
                                  onClick={() => {
                                    if (action.case === `changeSubscriptionTier`) {
                                      setPlanChange(action);
                                    } else if (action.case !== `startFullTrial`) {
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
      {planChange && (
        <Modal
          open
          onOpenChange={(open) => {
            if (!open && pendingAction === undefined) {
              setPlanChange(undefined);
            }
          }}
          title={`${actionLabel(planChange, billing)}?`}
          size="medium"
          dismissible={pendingAction === undefined}
          footer={
            <>
              <Button
                type="button"
                variant="ghost"
                disabled={pendingAction !== undefined}
                onClick={() => setPlanChange(undefined)}
              >
                Cancel
              </Button>
              <Button
                type="button"
                variant="primary"
                disabled={pendingAction !== undefined}
                loading={pendingAction !== undefined}
                onClick={async () => {
                  await onAction(planChange);
                  setPlanChange(undefined);
                }}
              >
                Confirm{` `}
                {actionLabel(planChange, billing).replace(/^./, (letter) =>
                  letter.toLowerCase(),
                )}
              </Button>
            </>
          }
        >
          <PlanChangeDescription billing={billing} to={planChange.to} />
        </Modal>
      )}
    </>
  );
};

export default BillingSettingsPage;

const PlanChangeDescription: React.FC<{
  billing: GetAccountBilling.Output;
  to: SubscriptionTier;
}> = ({ billing, to }) => {
  const { planStatus } = billing;
  const trial =
    planStatus.case === `fullTrial` || planStatus.case === `fullTrialGrace`
      ? planStatus
      : undefined;
  const from = trial ? trial.substrate?.tier : currentPlan(planStatus);
  if (!from) return null;

  return (
    <VStack gap={4}>
      <PlanChangeSummary
        from={from}
        to={to}
        currentPriceInCents={billing.currentPriceInCents}
        trialFeatures={trial ? PLANS.full.features : []}
        trialFeatureHeading={
          planStatus.case === `fullTrialGrace`
            ? `What you’ll keep after your grace period`
            : undefined
        }
      />
      <Text as="p" variant="bodyMuted">
        Your new plan and billing cycle start today. We’ll credit unused time on your
        current plan and charge any amount due to your saved payment method.
      </Text>
    </VStack>
  );
};

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
