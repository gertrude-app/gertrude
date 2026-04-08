import React from 'react';
import Callout from '../Callout';
import * as Onboarding from '../UtilityComponents';

const AppKeySelectionIntro: React.FC = () => (
  <Onboarding.Centered>
    <div className="flex flex-col items-center max-w-xl">
      <Onboarding.Heading centered>
        Let&rsquo;s set up your child&rsquo;s <em className="xunderline">apps</em>
      </Onboarding.Heading>
      <Onboarding.Text className="mt-4" centered>
        Gertrude lets you precisely control which apps on this Mac your child can use, and
        which ones can access the internet.
      </Onboarding.Text>
      <Onboarding.Text className="mt-4" centered>
        In the next two quick steps, you&rsquo;ll be able to <b>block apps</b> your child
        should never use, and <b>grant unrestricted internet access</b> to apps that you
        trust are safe.
      </Onboarding.Text>
      <Callout className="mt-4" type="info">
        <b>Web Browser</b> apps (like <em>Safari, Chrome, Firefox</em>) are handled
        separately&mdash;for those you pick which websites are allowed.
      </Callout>
      <Onboarding.ButtonGroup
        className="mt-8"
        direction="row"
        primary="Let's go"
        secondary={{ text: `Skip, I'll do this later`, shadow: true }}
      />
    </div>
  </Onboarding.Centered>
);

export default AppKeySelectionIntro;
