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
            So it's not safe to block only categories of the internet, but taking the
            reverse approach is <b>hard</b>. Rather than give up and settle for the
            illusion of safety, Gertrude makes this managable by letting you:
          </p>
          <div className="flex flex-col mt-4 sm:mt-6 items-center py-10 pb-0 -mx-8 sm:-mx-0">
            <Feature heading="Take complete control" side="left" icon="location">
              Choose exactly where your kids are allowed online, and make sure they can't
              go anwhere else.
            </Feature>
            <Feature heading="Manage on the go" side="right" icon="mobile">
              Add or remove sites from your own personal safelist from your phone or
              computer, wherever you are.
            </Feature>
            <Feature heading="Get notified" side="left" icon="bell">
              Get text, email, or Slack messages when your kid needs access to a blocked
              site.
            </Feature>
            <Feature heading="Suspend the filter" side="right" icon="stopwatch">
              Temporarily allow the whole internet, while recording screenshots of their
              activity and everything they type.
            </Feature>
            <Feature heading="Protect the whole family" side="left" icon="users">
              Manage all your kids with one account, sharing lists of safelisted sites
              when it makes sense.
            </Feature>
          </div>
        </div>
      </section>
    </section>
  );
};

export default SafeIsNowPossibleBlock;
