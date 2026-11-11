import { CheckIcon } from 'lucide-react';
import React from 'react';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { freeTrialDays, lightMonthlyEquivalentCents, pricingPlans } from '@/lib/pricing';
import { PARENTS_APP_URL } from '@/lib/urls';

const HomePricingSection: React.FC = () => (
  <section
    id="pricing"
    aria-labelledby="pricing-heading"
    className="scroll-mt-24 border-t border-stone-200/80 bg-white"
  >
    <HomeSectionRails className="bg-white pt-20 sm:pt-24 lg:pt-28">
      <div className="mx-auto max-w-3xl px-6 text-center sm:px-8">
        <h2
          id="pricing-heading"
          className="text-balance text-3xl font-medium !leading-[1.1] tracking-[-0.04em] text-stone-950 sm:text-4xl lg:text-[2.75rem]"
        >
          Plans for your whole family.
        </h2>
        <p className="mt-5 text-lg leading-7 text-stone-600">
          Start free. Add more apps as you need them.
        </p>
      </div>
      <ul
        aria-label="Gertrude plans"
        className="mt-12 grid gap-0 border-y border-stone-200 sm:grid-cols-2 lg:grid-cols-4"
      >
        {Object.values(pricingPlans).map((plan) => {
          const featured = plan.name === `Full`;
          const trialDays =
            plan.name === `Medium`
              ? freeTrialDays.music
              : featured
                ? freeTrialDays.mac
                : undefined;
          const ctaLabel =
            plan.name === `Free`
              ? `Get started free`
              : trialDays
                ? `Start free trial`
                : `Get ${plan.name}`;
          const priceLabel =
            plan.name === `Light`
              ? `${lightMonthlyEquivalentCents}¢`
              : `$${plan.priceDollars}`;
          const priceNote =
            plan.name === `Free`
              ? `For kids under 18`
              : plan.name === `Light`
                ? `$${plan.priceDollars} billed yearly`
                : `${trialDays}-day free${plan.name === `Medium` ? ` Music` : ``} trial`;

          return (
            <li
              key={plan.name}
              className={`flex h-full min-w-0 flex-col border-t border-stone-200 px-6 py-5 first:border-t-0 sm:odd:border-r sm:[&:nth-child(2)]:border-t-0 lg:border-r lg:border-t-0 lg:last:border-r-0 xl:px-8 xl:py-6 ${featured ? `bg-violet-50/60` : `bg-white`}`}
            >
              <div className="flex min-h-7 items-center justify-between gap-2">
                <h3
                  className={`text-lg font-medium ${featured ? `text-violet-700` : `text-stone-950`}`}
                >
                  {plan.name}
                </h3>
                {featured && (
                  <span className="rounded-full bg-violet-100 px-2 py-1 text-xs text-violet-700">
                    All four apps
                  </span>
                )}
              </div>
              <p className="mt-4 whitespace-nowrap">
                <span
                  className={`text-[2.75rem] font-medium leading-none tracking-[-0.05em] tabular-nums ${featured ? `text-violet-700` : `text-stone-950`}`}
                >
                  {priceLabel}
                </span>
                {plan.billingPeriod && (
                  <span className="ml-1.5 text-sm text-stone-500">/ month</span>
                )}
              </p>
              <p className="mt-1.5 min-h-5 text-[13px] leading-5 text-stone-500">
                {priceNote}
              </p>
              <p className="mt-4 text-[13px] leading-5 text-stone-600 sm:min-h-10">
                {plan.summary}
              </p>
              <ul
                aria-label={`${plan.name} plan features`}
                className="mt-3 flex-1 space-y-1.5"
              >
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-2">
                    <CheckIcon
                      aria-hidden="true"
                      className={`mt-0.5 size-3.5 shrink-0 ${featured ? `text-violet-500` : `text-stone-400`}`}
                    />
                    <span className="text-[13px] leading-5 text-stone-600">
                      {feature}
                    </span>
                  </li>
                ))}
              </ul>
              <HomeButtonLink
                href={`${PARENTS_APP_URL}/signup?v=new_site`}
                aria-label={`${ctaLabel} with the ${plan.name} plan`}
                size="hero"
                variant={featured ? `primary` : `secondary`}
                className="mt-6 w-full"
              >
                {ctaLabel}
              </HomeButtonLink>
            </li>
          );
        })}
      </ul>
      <div className="mx-auto max-w-3xl px-6 py-10 text-center sm:px-8 sm:py-12">
        <p className="text-sm leading-6 text-stone-500">
          Try Music free for {freeTrialDays.music} days, Mac for {freeTrialDays.mac}, and
          Podcasts for {freeTrialDays.podcasts}. No credit card required.
        </p>
        <p className="mt-2 text-xs leading-5 text-stone-500">
          Gertrude Music requires an Apple Music subscription, sold separately.
        </p>
      </div>
    </HomeSectionRails>
  </section>
);

export default HomePricingSection;
