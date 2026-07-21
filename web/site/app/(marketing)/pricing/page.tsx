import cx from 'classnames';
import { CheckIcon, MinusIcon, RocketIcon } from 'lucide-react';
import React from 'react';
import type { NextPage } from 'next';
import Button from '@/components/Button';
import { createMetadata } from '@/lib/seo';
import { PARENTS_APP_URL } from '@/lib/urls';

export const metadata = createMetadata(
  `Pricing | One Gertrude Account for Your Whole Family`,
  `Simple, layered plans for your whole family. Start free, add Gertrude Podcasts and iOS supervision with Light ($10/year), add parent-curated music with Medium ($5/month), or get everything including the Mac app with Full ($10/month).`,
);

const SIGNUP_URL = `${PARENTS_APP_URL}/signup?v=new_site`;

interface Tier {
  name: string;
  priceMain: string;
  priceAccent?: string;
  pricePeriod?: string;
  billing: string;
  free?: boolean;
  blurb: string;
  inheritsFrom?: string;
  includes: string[];
  trial?: string;
  cta: { label: string; variant: `primary` | `secondary` };
  featured?: boolean;
}

const TIERS: Tier[] = [
  {
    name: `Free`,
    priceMain: `Free`,
    billing: `Always free`,
    free: true,
    blurb: `Basic protection to get started.`,
    includes: [
      `Basic iOS blocking: GIFs, Spotlight & Maps loopholes`,
      `30-day Gertrude Podcasts trial`,
    ],
    cta: { label: `Create free account`, variant: `secondary` },
  },
  {
    name: `Light`,
    priceMain: `83`,
    priceAccent: `¢`,
    pricePeriod: `/mo`,
    billing: `Just $10 a year · billed yearly`,
    blurb: `Safe podcasts and supervision for iOS families.`,
    inheritsFrom: `Free`,
    includes: [`Gertrude Podcasts: kid-safe podcast app`, `iOS device supervision`],
    cta: { label: `Get Light`, variant: `secondary` },
  },
  {
    name: `Medium`,
    priceMain: `$5`,
    pricePeriod: `/mo`,
    billing: `Billed monthly`,
    blurb: `Adds safe, parent-curated music for your kids.`,
    inheritsFrom: `Light`,
    includes: [`Gertrude Music: parent-approved Apple Music albums`],
    cta: { label: `Get Medium`, variant: `secondary` },
  },
  {
    name: `Full`,
    priceMain: `$10`,
    pricePeriod: `/mo`,
    billing: `Billed monthly`,
    blurb: `Everything Gertrude makes, including Mac.`,
    inheritsFrom: `Medium`,
    includes: [`Gertrude for Mac: full web filtering & monitoring`],
    trial: `21-day free trial`,
    cta: { label: `Start free trial`, variant: `primary` },
    featured: true,
  },
];

const INCLUDES = [`Covers your whole family`, `No ads, ever`, `Cancel anytime`];

interface FeatureRow {
  label: string;
  free: boolean | string;
  light: boolean;
  medium: boolean;
  full: boolean;
}

const MATRIX: FeatureRow[] = [
  { label: `Basic iOS blocking`, free: true, light: true, medium: true, full: true },
  {
    label: `Gertrude Podcasts`,
    free: `30-day trial`,
    light: true,
    medium: true,
    full: true,
  },
  { label: `iOS device supervision`, free: false, light: true, medium: true, full: true },
  { label: `Gertrude Music`, free: false, light: false, medium: true, full: true },
  { label: `Gertrude for Mac`, free: false, light: false, medium: false, full: true },
];

const PricingPage: NextPage = () => (
  <main className="relative overflow-hidden bg-gradient-to-b from-violet-500 via-violet-900 to-slate-950">
    <div className="[background:radial-gradient(#c4b5fd55,transparent_70%)] w-176 h-176 absolute -right-72 -top-72 pointer-events-none" />
    <div className="[background:radial-gradient(#e879f944,transparent_70%)] w-176 h-176 absolute -left-80 top-96 pointer-events-none" />

    <section className="relative px-5 xs:px-8 sm:px-12 md:px-20 pt-36 xs:pt-40 md:pt-48 pb-12 text-center">
      <div
        className="inline-block px-4 py-1.5 bg-white/10 backdrop-blur-sm rounded-full mb-6 border border-white/20 animate-fadeIn opacity-0"
        style={{ animationDelay: `100ms`, animationFillMode: `forwards` }}
      >
        <span className="text-xs xs:text-sm font-bold bg-gradient-to-r from-violet-200 to-fuchsia-200 bg-clip-text text-transparent tracking-wider">
          PRICING
        </span>
      </div>
      <h1
        className="text-4xl xs:text-5xl md:text-6xl font-bold text-white !leading-[1em] max-w-4xl mx-auto px-2 animate-fadeIn opacity-0"
        style={{ animationDelay: `200ms`, animationFillMode: `forwards` }}
      >
        One account,{` `}
        <span className="bg-gradient-to-r from-fuchsia-400 to-amber-300 bg-clip-text text-transparent pr-1 -mr-1">
          your whole family
        </span>
        , every device
      </h1>
      <p
        className="mt-6 text-base xs:text-lg md:text-xl text-violet-200/90 max-w-2xl mx-auto leading-relaxed animate-fadeIn opacity-0"
        style={{ animationDelay: `350ms`, animationFillMode: `forwards` }}
      >
        Start with a free account. Each plan builds on the last, and every tier covers
        your whole family, with no ads, ever.
      </p>
    </section>

    <section className="relative px-5 xs:px-8 sm:px-12 lg:px-20 pb-6">
      <div className="max-w-md lg:max-w-4xl xl:max-w-7xl mx-auto grid gap-5 xs:gap-6 lg:grid-cols-2 xl:grid-cols-4 items-stretch">
        {TIERS.map((tier, index) => (
          <TierCard key={tier.name} tier={tier} index={index} />
        ))}
      </div>
      <ul className="max-w-6xl mx-auto mt-9 flex flex-wrap items-center justify-center gap-x-6 gap-y-2.5 text-sm text-violet-200/80">
        {INCLUDES.map((item) => (
          <li key={item} className="flex items-center gap-1.5">
            <CheckIcon className="size-4 text-fuchsia-300" />
            {item}
          </li>
        ))}
      </ul>
    </section>

    <section className="relative px-5 xs:px-8 sm:px-12 lg:px-20 pt-14 pb-4">
      <div className="max-w-4xl mx-auto">
        <h2 className="text-center text-2xl font-semibold text-white mb-8">
          Compare plans
        </h2>
        <div className="rounded-3xl bg-white/5 backdrop-blur-sm border border-white/10 px-4 xs:px-5 sm:px-8 py-5 shadow-xl shadow-black/20">
          <ComparisonTable />
        </div>
      </div>
    </section>

    <section className="relative px-5 xs:px-8 sm:px-12 md:px-20 pt-16 pb-24 xs:pb-32">
      <div className="max-w-3xl mx-auto text-center">
        <h2 className="text-3xl xs:text-4xl md:text-5xl font-bold text-white !leading-[1.15em]">
          Protect everyone,{` `}
          <span className="bg-gradient-to-r from-violet-200 to-fuchsia-200 bg-clip-text text-transparent">
            from one place.
          </span>
        </h2>
        <p className="mt-5 text-base xs:text-lg text-violet-200/90 leading-relaxed max-w-2xl mx-auto">
          Start with a free account and add the plan that fits. Every plan covers your
          whole family, and you can upgrade, switch, or cancel anytime.
        </p>
        <div className="mt-10 flex flex-col xs:flex-row items-center justify-center gap-4">
          <Button
            type="link"
            href={SIGNUP_URL}
            color="primary"
            size="lg"
            Icon={RocketIcon}
            className="w-full xs:w-auto"
          >
            Get started free
          </Button>
          <Button
            type="link"
            href={PARENTS_APP_URL}
            color="secondary"
            size="lg"
            inverted
            variant="flat"
            className="w-full xs:w-auto"
          >
            Log in
          </Button>
        </div>
      </div>
    </section>
  </main>
);

export default PricingPage;

const TierCard: React.FC<{ tier: Tier; index: number }> = ({ tier, index }) => (
  <div
    className={cx(`relative rounded-3xl animate-fadeIn opacity-0`, {
      'bg-gradient-to-b from-violet-400 to-fuchsia-500 p-[1.5px] shadow-2xl shadow-fuchsia-500/20 lg:-translate-y-3':
        tier.featured,
      'bg-white/10 p-px': !tier.featured,
    })}
    style={{ animationDelay: `${300 + index * 120}ms`, animationFillMode: `forwards` }}
  >
    {tier.featured && (
      <div className="absolute -inset-2 -z-10 rounded-3xl bg-gradient-to-b from-violet-500/20 to-fuchsia-500/20 blur-2xl" />
    )}
    <div className="flex flex-col h-full bg-slate-900/80 rounded-[22px] p-6 xs:p-7">
      <div className="flex items-center gap-3 mb-4">
        <h3 className="text-lg font-semibold text-white">{tier.name}</h3>
        {tier.featured && (
          <span className="ml-auto text-[0.65rem] font-bold uppercase tracking-wider text-violet-100 bg-white/10 border border-white/20 rounded-full px-2.5 py-0.5">
            Everything
          </span>
        )}
      </div>
      <div className="mb-1.5">
        <div className="flex items-baseline gap-1.5">
          <span
            className={cx(
              `text-5xl font-black tracking-tight bg-clip-text text-transparent`,
              tier.free
                ? `bg-gradient-to-r from-green-400 to-emerald-400`
                : `bg-gradient-to-r from-white to-violet-200`,
            )}
          >
            {tier.priceMain}
            {tier.priceAccent && (
              <span
                className="inline-block origin-bottom text-violet-200"
                style={{ animation: `cent-waggle 0.8s ease-in-out 1.3s` }}
              >
                {tier.priceAccent}
              </span>
            )}
          </span>
          {tier.pricePeriod && (
            <span className="text-violet-200 text-2xl font-bold">{tier.pricePeriod}</span>
          )}
        </div>
        <p className="text-xs text-violet-300/70 mt-1.5 font-medium">{tier.billing}</p>
      </div>
      <p className="text-sm text-violet-200/80 leading-snug min-h-[2.5rem] mb-5">
        {tier.blurb}
      </p>
      <ul className="flex flex-col gap-2.5 mb-6">
        {tier.inheritsFrom && (
          <li className="text-sm font-medium text-violet-100/90">
            Everything in {tier.inheritsFrom}, plus:
          </li>
        )}
        {tier.includes.map((feature) => (
          <li
            key={feature}
            className="flex items-start gap-2.5 text-sm text-violet-100/90"
          >
            <CheckIcon className="size-4 mt-0.5 shrink-0 text-fuchsia-300" />
            <span className="leading-snug">{feature}</span>
          </li>
        ))}
      </ul>
      <div className="mt-auto">
        {tier.trial && <p className="text-xs text-violet-300/60 mb-3">{tier.trial}</p>}
        <Button
          type="link"
          href={SIGNUP_URL}
          size="sm"
          color={tier.cta.variant}
          inverted={tier.cta.variant === `secondary`}
          className="w-full"
        >
          {tier.cta.label}
        </Button>
      </div>
    </div>
  </div>
);

const ComparisonTable: React.FC = () => (
  <>
    <table className="hidden md:table w-full border-collapse text-left">
      <thead>
        <tr>
          <th className="w-2/5" />
          {TIERS.map((tier) => (
            <th
              key={tier.name}
              className={cx(`py-4 px-3 text-center align-bottom`, {
                'bg-violet-500/40 rounded-t-2xl': tier.featured,
              })}
            >
              <div
                className={cx(
                  `font-semibold`,
                  tier.featured ? `text-white` : `text-white/55`,
                )}
              >
                {tier.name}
              </div>
              <div
                className={cx(
                  `text-sm font-medium`,
                  tier.featured ? `text-violet-100` : `text-violet-200/50`,
                )}
              >
                {tier.free
                  ? `$0`
                  : `${tier.priceMain}${tier.priceAccent ?? ``}${tier.pricePeriod}`}
              </div>
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {MATRIX.map((row) => (
          <tr key={row.label} className="border-t border-white/10">
            <td className="py-4 pr-3 text-violet-100/70 text-sm">{row.label}</td>
            <MatrixCell value={row.free} />
            <MatrixCell value={row.light} />
            <MatrixCell value={row.medium} />
            <MatrixCell value={row.full} featured />
          </tr>
        ))}
        <tr aria-hidden="true">
          <td />
          <td />
          <td />
          <td />
          <td className="h-4 bg-violet-500/40 rounded-b-2xl" />
        </tr>
      </tbody>
    </table>
    <div className="md:hidden divide-y divide-white/10">
      {MATRIX.map((row) => (
        <div key={row.label} className="py-4 first:pt-0 last:pb-0">
          <h3 className="text-center text-sm font-semibold text-violet-50">
            {row.label}
          </h3>
          <div className="mt-3 grid grid-cols-4 gap-1.5">
            <MobileMatrixCell plan="Free" value={row.free} />
            <MobileMatrixCell plan="Light" value={row.light} />
            <MobileMatrixCell plan="Med" value={row.medium} />
            <MobileMatrixCell plan="Full" value={row.full} featured />
          </div>
        </div>
      ))}
    </div>
  </>
);

const MatrixCell: React.FC<{ value: boolean | string; featured?: boolean }> = ({
  value,
  featured,
}) => (
  <td className={cx(`py-4 px-3 text-center`, { 'bg-violet-500/40': featured })}>
    <MatrixValue value={value} featured={featured} />
  </td>
);

const MobileMatrixCell: React.FC<{
  plan: string;
  value: boolean | string;
  featured?: boolean;
}> = ({ plan, value, featured }) => (
  <div
    className={cx(
      `px-2 py-2.5 text-center`,
      featured && `rounded-2xl bg-white/10 shadow-inner shadow-white/5`,
    )}
  >
    <div
      className={cx(
        `text-[0.65rem] font-bold uppercase tracking-wider`,
        featured ? `text-white` : `text-violet-200/55`,
      )}
    >
      {plan}
    </div>
    <div className="mt-1.5 flex min-h-5 items-center justify-center">
      <MatrixValue value={value} featured={featured} />
    </div>
  </div>
);

const MatrixValue: React.FC<{ value: boolean | string; featured?: boolean }> = ({
  value,
  featured,
}) => {
  if (typeof value === `string`) {
    return (
      <span
        className={cx(
          `text-[0.7rem] font-medium leading-tight`,
          featured ? `text-violet-100/90` : `text-violet-200/65`,
        )}
      >
        {value}
      </span>
    );
  }
  if (value) {
    return (
      <CheckIcon
        className={cx(`size-5 mx-auto`, featured ? `text-white` : `text-fuchsia-300/70`)}
      />
    );
  }
  return <MinusIcon className="size-4 mx-auto text-white/20" />;
};
