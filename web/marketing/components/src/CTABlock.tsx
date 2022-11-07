import React from 'react';

const CTABlock: React.FC = () => (
  <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 flex justify-center items-center flex-col md:p-28 p-10 py-14 md:py-28">
    <h2 className="text-white text-opacity-70 text-4xl font-bold mb-5 text-center">
      $10/month. 30 day free trial.{` `}
      <span className="text-white text-opacity-90 font-extrabold">
        Early access available now.
      </span>
    </h2>
    <a
      className="text-white font-extrabold text-3xl bg-gray-800 px-10 py-4 rounded-xl shadow-xl mt-8 hover:bg-gray-900 transition duration-150 flex items-center"
      href="https://dash.gertrude.app/signup"
    >
      <i aria-hidden className="fas fa-rocket mr-4" />
      <h2 className="leading-[90%]">Signup now</h2>
    </a>
  </section>
);

export default CTABlock;
