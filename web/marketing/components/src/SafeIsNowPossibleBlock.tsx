import React from 'react';
import Feature from './Feature';

const SafeIsNowPossibleBlock: React.FC = () => {
  return (
    <section className="bg-gray-100 bg-topo">
      <section className="relative">
        <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -right-96 top-0 z-10" />
        <div className="w-176 h-176 absolute bg-fuchsia-radial-gradient -left-96 top-128 z-10" />
        <div className="lg:p-20 p-10 py-20">
          <h2 className="font-inter text-5xl">
            Safe is now{` `}
            <span
              className="relative line-through [text-decoration-thickness:5px] [text-decoration-color:#d946ef]"
              aria-hidden="true"
            >
              easy
            </span>
            {` `}
            <span className="bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent">
              possible
            </span>
          </h2>
          <p className="text-xl text-gray-500 mt-8 leading-8 max-w-4xl">
            So you can't just block categories of the internet, but taking the reverse
            approach is <b>hard</b>. Rather than give up and settle for the illusion of
            safety, Gertrude makes this managable by letting you:
          </p>
          <div className="flex flex-wrap justify-center items-stretch py-10 pb-0 lg:pb-10 -mx-7 sm:-mx-0">
            <Feature icon="mobile">
              Unlock websites and apps from wherever you are, on your own computer or
              phone.
            </Feature>
            <Feature icon="share">
              Share unblock settings and protection rules between multiple users.
            </Feature>
            <Feature icon="key">
              Select curated lists of unblocking rules for instant access to commonly used
              websites and apps.
            </Feature>
            <Feature icon="bell">
              Get text, email, or Slack notifications wherever you are when someone needs
              something unblocked.
            </Feature>
            <Feature icon="eye">
              Remotely suspend your users filter temporarily, while uploading screenshots
              of their activity for your later review.
            </Feature>
          </div>
        </div>
      </section>
    </section>
  );
};

export default SafeIsNowPossibleBlock;
