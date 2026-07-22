import React from 'react';

const ProblemBlock: React.FC = () => (
  <section
    id="how-it-works"
    className="scroll-mt-8 bg-white px-4 py-24 text-slate-900 xs:px-8 sm:px-12 sm:py-32 md:px-20 lg+:py-40"
  >
    <div className="mx-auto grid max-w-7xl items-center gap-12 lg+:grid-cols-[0.9fr_1.1fr] lg+:gap-20">
      <div className="max-w-xl">
        <h2 className="text-4xl font-semibold leading-[1.05] tracking-[-0.045em] xs:text-5xl lg+:text-6xl">
          Not a filter.
          <br />A library you choose.
        </h2>
        <p className="mt-7 text-lg leading-relaxed text-slate-600">
          Most controls start with the whole catalog and try to filter out the bad stuff.
          Gertrude Music starts empty. A parent adds only the artists and albums they want
          their children listening to.
        </p>

        <div className="mt-9 grid gap-4 sm:grid-cols-2">
          <Role
            title="For parents"
            body="Search Apple Music and approve artists or albums from your Gertrude account."
          />
          <Role
            title="For listeners"
            body="Enjoy the approved library—with no open search, feeds, or recommendations."
          />
        </div>

        <p className="mt-6 text-sm leading-relaxed text-slate-500">
          A trusted accountability partner can manage the library in the same way.
        </p>
      </div>

      <div className="relative isolate">
        <div className="pointer-events-none absolute left-[2%] top-[18%] h-[64%] w-[64%] rounded-full bg-violet-500/55 blur-[56px] sm:blur-[80px]" />
        <div className="pointer-events-none absolute right-[1%] top-[16%] h-[62%] w-[38%] rounded-full bg-fuchsia-400/55 blur-[52px] sm:blur-[76px]" />
        <img
          src="/music/approved-library-visual.webp"
          alt="A parent selects four albums from a larger catalog and those albums appear in the child's Gertrude Music library"
          width={1448}
          height={1086}
          className="relative z-10 w-full"
        />
      </div>
    </div>
  </section>
);

export default ProblemBlock;

const Role: React.FC<{ title: string; body: string }> = ({ title, body }) => (
  <div className="rounded-2xl bg-violet-50 p-5">
    <h3 className="font-semibold text-violet-700">{title}</h3>
    <p className="mt-2 text-sm leading-relaxed text-slate-600">{body}</p>
  </div>
);
