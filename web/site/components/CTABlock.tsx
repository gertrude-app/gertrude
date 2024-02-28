import React from 'react';
import { RocketIcon, RouteIcon } from 'lucide-react';
import cx from 'classnames';
import { axiforma } from '../lib/fonts';
import FancyLink from './FancyLink';

const CTABlock: React.FC = () => (
  <section className="bg-gradient-to-b from-violet-500 to-violet-500 xl:p-8 pb-0 relative">
    <div className="px-4 xs:px-8 sm:px-12 lg:px-20 py-20 xs:py-24 md:py-40 rounded-t-[40px] xs:rounded-b-[40px] bg-slate-900 flex flex-col items-center -translate-y-40">
      <h2
        className={cx(
          `text-4xl md:text-5xl font-semibold text-center !leading-[1.2em] text-white`,
          axiforma,
        )}
      >
        $5 a month, for the whole family.
      </h2>
      <h3
        className={cx(
          `text-3xl md:text-4xl font-semibold mt-4 bg-gradient-to-r from-white to-violet-200 bg-clip-text text-transparent`,
          axiforma,
        )}
      >
        60 day free trial.
      </h3>
      <div className="flex flex-col md:flex-row justify-center self-stretch md:items-center gap-6 md:gap-4 mt-12">
        <FancyLink
          type="link"
          href="https://parents.gertrude.app/signup"
          Icon={RocketIcon}
        >
          Start free trial
        </FancyLink>
        <FancyLink
          type="link"
          href="https://parents.gertrude.app/signup"
          Icon={RouteIcon}
          color="secondary"
          inverted
        >
          Step-by-step guide
        </FancyLink>
      </div>
    </div>
  </section>
);

export default CTABlock;
