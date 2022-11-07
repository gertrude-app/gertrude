import React from 'react';

const CTABlock: React.FC = () => (
  <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 flex justify-center items-center flex-col md:p-28 p-10 py-14 md:py-28">
    <h2 className="text-white text-opacity-70 text-4xl font-bold mb-5 text-center">
      $10/month. 30 day free trial.{` `}
      <span className="text-white text-opacity-90 font-extrabold">
        Early access available now.
      </span>
    </h2>
    <div className="flex flex-col sm:flex-row items-center justify-center mt-8 gap-6">
      <a
        className="text-white font-extrabold text-3xl bg-gray-800 px-10 py-4 rounded-xl shadow-xl hover:bg-gray-900 transition duration-150 flex items-center"
        href="https://dash.gertrude.app/signup"
      >
        <i aria-hidden className="fas fa-rocket mr-4" />
        <span className="whitespace-nowrap">Signup now</span>
      </a>
      <a
        className="bg-white/20 rounded-lg py-[19px] px-12 sm:px-6 inline-block text-white/80 whitespace-nowrap"
        href="https://docs.gertrude.app"
      >
        &rdquo;Getting Started&ldquo; tutorial &rarr;
      </a>
    </div>
  </section>
);

export default CTABlock;
