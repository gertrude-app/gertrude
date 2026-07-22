import { ArrowRightIcon, CheckIcon } from 'lucide-react';
import React from 'react';
import { AppStoreLink } from './shared';
import Button from '@/components/Button';

const PricingBlock: React.FC = () => (
  <section className="bg-violet-50 px-4 py-24 xs:px-8 sm:px-12 sm:py-32 md:px-20 lg:py-40">
    <div className="relative mx-auto grid max-w-6xl overflow-hidden rounded-[2rem] bg-gradient-to-br from-violet-600 to-fuchsia-500 p-8 text-white shadow-2xl shadow-violet-900/15 sm:rounded-[2.5rem] sm:p-12 lg:grid-cols-[0.85fr_1.15fr] lg:gap-16 lg:p-16">
      <div className="pointer-events-none absolute -left-28 -top-28 size-80 rounded-full bg-white/10 blur-3xl" />
      <div className="relative">
        <p className="text-sm font-semibold uppercase tracking-[0.16em] text-violet-100">
          Gertrude Medium
        </p>
        <div className="mt-6 flex items-end gap-3">
          <span className="text-7xl font-semibold tracking-[-0.07em] sm:text-8xl">
            $5
          </span>
          <span className="pb-3 text-white/70">per month</span>
        </div>
        <p className="mt-5 font-semibold">One subscription covers your whole family.</p>
      </div>

      <div className="relative mt-12 lg:mt-0">
        <h2 className="font-semibold leading-[1.05] tracking-[-0.04em]">
          <span className="block text-3xl text-white/65 sm:text-4xl">One plan.</span>
          <span className="mt-2 block text-4xl sm:text-5xl">The whole family.</span>
        </h2>
        <ul className="mt-7 space-y-3 text-sm sm:text-base">
          <Included>Gertrude Music for every listener in your family</Included>
          <Included>Parent management from any browser</Included>
        </ul>
        <div className="mt-8 flex flex-col items-start gap-3 xs:flex-row xs:flex-wrap xs:items-center sm:gap-4">
          <AppStoreLink />
          <Button
            type="link"
            href="/pricing"
            color="secondary"
            inverted
            Icon={ArrowRightIcon}
            iconPosition="right"
            className="max-sm:px-4"
          >
            Compare plans
          </Button>
        </div>
        <p className="mt-7 max-w-xl text-xs leading-relaxed text-white/55">
          The app is free to download. Listening requires Medium or Full and an active
          Apple Music subscription. Apple Music is sold separately.
        </p>
      </div>
    </div>
  </section>
);

export default PricingBlock;

const Included: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <li className="flex items-start gap-3">
    <span className="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full bg-white/15">
      <CheckIcon className="size-3.5" />
    </span>
    {children}
  </li>
);
