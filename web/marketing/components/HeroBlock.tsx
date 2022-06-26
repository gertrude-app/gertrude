import React from "react";

const HeroBlock: React.FC = () => {
  return (
    <section className="flex justify-center items-center sm:p-20 p-10 py-20 bg-gradient-to-b from-violet-500 to-fuchsia-500">
      <h1 className="text-white lg:text-6xl  text-5xl font-extrabold text-opacity-70 text-center">
        Finally, real{" "}
        <span className="text-white text-opacity-100">internet safety</span> is
        possible
      </h1>
    </section>
  );
};

export default HeroBlock;
