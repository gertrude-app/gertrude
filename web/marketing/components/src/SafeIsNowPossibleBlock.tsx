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
          <p className="text-xl text-gray-500 mt-8 leading-8">
            Gertrude blocks the entire internet, only allowing parts you specifically
            unlock. We make this managable by letting you:
          </p>
          <div className="flex flex-wrap justify-center items-stretch py-10 pb-0 lg:pb-10 -mx-7 sm:-mx-0">
            <Feature icon="mobile">
              Unlock websites and apps from wherever you are, on your own computer or
              phone
            </Feature>
            <Feature icon="share">
              Share protection settings and filter rules between multiple users
            </Feature>
            <Feature icon="key">
              Mix, match, and borrow groups of keys to unlock websites and apps
            </Feature>
            <Feature icon="bell">
              Get text, email, or Slack notifications wherever you are when someone needs
              something unblocked
            </Feature>
            <Feature icon="eye">
              Easily see which requests are being blocked and request unlocking
            </Feature>
          </div>
        </div>
      </section>
    </section>
  );
};

export default SafeIsNowPossibleBlock;
