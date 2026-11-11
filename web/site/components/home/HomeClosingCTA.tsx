import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { PARENTS_APP_URL } from '@/lib/urls';

const HomeClosingCTA: React.FC = () => (
  <section
    id="get-started"
    aria-labelledby="get-started-heading"
    data-home-header-theme="dark-static"
    className="scroll-mt-24 bg-stone-950 text-stone-50"
  >
    <HomeSectionRails inverted className="px-6 py-24 text-center sm:px-12 sm:py-28">
      <h2
        id="get-started-heading"
        className="mx-auto max-w-4xl text-balance text-4xl font-medium !leading-[1.1] tracking-[-0.04em] sm:text-5xl lg:text-6xl"
      >
        Ready when you are.
      </h2>
      <p className="mx-auto mt-5 max-w-xl text-base leading-7 text-stone-300 sm:text-lg">
        Create a free account and choose the apps you need.
      </p>
      <HomeButtonLink
        href={`${PARENTS_APP_URL}/signup?v=new_site`}
        size="hero"
        variant="primary"
        inverted
        className="mt-8 !bg-violet-600 hover:!bg-violet-700"
      >
        Get started free
        <ArrowRightIcon aria-hidden="true" className="size-4" />
      </HomeButtonLink>
      <p className="mt-4 text-xs leading-5 text-stone-400">No credit card required.</p>
    </HomeSectionRails>
  </section>
);

export default HomeClosingCTA;
