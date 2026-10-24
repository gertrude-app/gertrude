import { HStack, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, MinusIcon } from 'lucide-react';
import React from 'react';
import {
  FEATURES,
  type FeatureId,
  PLANS,
  type PlanId,
  planFeatures,
  planPriceDisplay,
} from '#/lib/plans';

interface Props {
  from: PlanId;
  to: PlanId;
  currentPriceInCents?: number;
  trialFeatures?: FeatureId[];
  trialFeatureHeading?: string;
}

const PlanChangeSummary: React.FC<Props> = ({
  from,
  to,
  currentPriceInCents,
  trialFeatures = [],
  trialFeatureHeading = `What you’ll keep after your trial`,
}) => {
  const arrowGradientId = React.useId();
  const current = PLANS[from];
  const destination = PLANS[to];
  const currentPrice = {
    ...current.price,
    cents: currentPriceInCents ?? current.price.cents,
  };
  const priceDifference =
    destination.price.cents / (destination.price.interval === `year` ? 12 : 1) -
    currentPrice.cents / (currentPrice.interval === `year` ? 12 : 1);
  const higherIndex = priceDifference > 0 ? 1 : priceDifference < 0 ? 0 : undefined;
  const arrowStart = priceDifference > 0 ? 64 : 40;
  const arrowEnd = priceDifference < 0 ? 64 : 40;
  const prices = [
    {
      plan: current,
      price: planPriceDisplay(currentPrice),
      column: `col-start-1`,
    },
    {
      plan: destination,
      price: planPriceDisplay(destination.price),
      column: `col-start-3`,
    },
  ];
  const currentFeatures = planFeatures(from);
  const destinationFeatures = planFeatures(to);
  const added = destinationFeatures.filter(
    (feature) => !currentFeatures.includes(feature),
  );
  const removed = currentFeatures.filter(
    (feature) => !destinationFeatures.includes(feature),
  );
  const groups = [
    {
      heading: `What you’re adding`,
      features: added.filter((feature) => !trialFeatures.includes(feature)),
      removed: false,
    },
    {
      heading: trialFeatureHeading,
      features: added.filter((feature) => trialFeatures.includes(feature)),
      removed: false,
    },
    {
      heading: `What you’re giving up`,
      features: removed,
      removed: true,
    },
  ];

  return (
    <VStack gap={4}>
      <div className="mx-auto grid w-full max-w-xs grid-cols-[1fr_4rem_1fr] items-start gap-x-2 pt-8 pb-5 text-center">
        {prices.map(({ plan, price, column }, index) => (
          <VStack
            key={column}
            gap={1}
            className={cx(
              column,
              `relative isolate row-start-1 w-fit items-center justify-self-center`,
              higherIndex !== undefined && higherIndex !== index && `mt-6`,
            )}
          >
            {higherIndex === index && (
              <div aria-hidden className="pointer-events-none absolute -inset-3 -z-10">
                <div className="absolute -inset-x-8 -inset-y-5 bg-[radial-gradient(ellipse_closest-side_at_center,var(--color-violet-400),transparent)] opacity-20" />
                {[
                  `left-0 top-3 size-1 bg-violet-400`,
                  `right-1 top-0 size-1 bg-fuchsia-400`,
                  `-left-1 top-1/2 size-1 bg-fuchsia-400`,
                  `-right-1 top-8 size-1.5 bg-violet-400`,
                  `bottom-0 left-3 size-1 bg-violet-400`,
                  `bottom-1 right-2 size-1 bg-fuchsia-400`,
                ].map((dot, dotIndex) => (
                  <span
                    key={dot}
                    className={cx(
                      `absolute rounded-full motion-safe:animate-[plan-price-dot-float_4s_ease-in-out_infinite]`,
                      dot,
                    )}
                    style={{
                      animationDuration: `${3.5 + dotIndex * 0.4}s`,
                      animationDelay: `${dotIndex * -0.63}s`,
                    }}
                  />
                ))}
              </div>
            )}
            <Text
              variant="captionMuted"
              className={higherIndex === index ? `text-violet-700` : undefined}
            >
              {plan.name}
            </Text>
            <span
              className={cx(
                `text-4xl font-semibold tracking-tight tabular-nums`,
                higherIndex === index ? `text-violet-950` : `text-stone-950`,
              )}
            >
              {price.amount}
            </span>
            {price.cadence && (
              <Text
                variant="captionMuted"
                className={higherIndex === index ? `text-violet-700` : undefined}
              >
                {price.cadence}
              </Text>
            )}
            {price.billingNote && (
              <Text
                variant="captionMuted"
                className={higherIndex === index ? `text-violet-700` : undefined}
              >
                {price.billingNote}
              </Text>
            )}
          </VStack>
        ))}
        <svg
          viewBox="0 0 64 120"
          fill="none"
          stroke={`url(#${arrowGradientId})`}
          strokeWidth={2}
          strokeLinecap="round"
          strokeLinejoin="round"
          className="col-start-2 row-start-1 h-[120px] w-full"
          aria-hidden
        >
          <defs>
            <linearGradient
              id={arrowGradientId}
              gradientUnits="userSpaceOnUse"
              x1={4}
              y1={0}
              x2={60}
              y2={0}
            >
              <stop
                offset="0%"
                stopColor={
                  higherIndex === 0 ? `var(--color-violet-400)` : `var(--color-stone-400)`
                }
              />
              <stop
                offset="100%"
                stopColor={
                  higherIndex === 1 ? `var(--color-violet-400)` : `var(--color-stone-400)`
                }
              />
            </linearGradient>
          </defs>
          <path
            d={
              priceDifference === 0
                ? `M4 40 C18 40 18 34 32 40 S46 40 60 40`
                : `M4 ${arrowStart} C32 ${arrowStart} 32 ${arrowEnd} 60 ${arrowEnd}`
            }
          />
          <path d={`M54 ${arrowEnd - 6} L60 ${arrowEnd} L54 ${arrowEnd + 6}`} />
        </svg>
      </div>

      {groups
        .filter((group) => group.features.length > 0)
        .map((group) => (
          <VStack key={group.heading} gap={2}>
            <Text as="h3" variant="bodyStrong">
              {group.heading}
            </Text>
            <VStack as="ul" gap={2}>
              {group.features.map((feature) => {
                const Icon = group.removed ? MinusIcon : CheckIcon;
                return (
                  <HStack as="li" key={feature} align="start" gap={2}>
                    <Icon
                      className={cx(
                        `mt-0.5 h-4 w-4 shrink-0`,
                        group.removed ? `text-amber-600` : `text-violet-600`,
                      )}
                      aria-hidden
                    />
                    <Text variant="bodySubtle">{FEATURES[feature]}</Text>
                  </HStack>
                );
              })}
            </VStack>
          </VStack>
        ))}
    </VStack>
  );
};

export default PlanChangeSummary;
