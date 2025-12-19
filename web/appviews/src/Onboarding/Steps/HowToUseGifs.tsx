import React from 'react';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';

const HowToUseGifs: React.FC = () => (
  <Onboarding.Centered className="space-x-12" direction="row">
    <div className="flex flex-col">
      <Onboarding.Heading className="mb-2">Tips for instruction GIFs</Onboarding.Heading>
      <Onboarding.Text className="my-4 max-w-xl">
        In the next few sections, we’ll show you what you need to do using animated GIFs.
      </Onboarding.Text>
      <Onboarding.Text>
        Try <b>enlarging</b> and <b>pausing</b> right now{` `}
        <b className="text-2xl inline-block translate-y-0.5 pl-1">&rarr;</b>
      </Onboarding.Text>
      <Onboarding.PrimaryButton className="mt-8">Got it, next</Onboarding.PrimaryButton>
    </div>
    <ExpandableContent
      asset={assets.img(`how-to-use-gifs`)}
      width={800 / 2.1}
      height={600 / 2.1}
    />
  </Onboarding.Centered>
);

export default HowToUseGifs;
