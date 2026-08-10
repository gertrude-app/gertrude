import { ChevronDownIcon } from 'lucide-react';
import React from 'react';
import { AppStoreLink } from './shared';

const FaqBlock: React.FC = () => (
  <section className="bg-white px-4 py-24 text-slate-900 xs:px-8 sm:px-12 sm:py-32 md:px-20 lg:py-40">
    <div className="mx-auto max-w-4xl">
      <div className="text-center">
        <p className="text-sm font-semibold uppercase tracking-[0.16em] text-violet-600">
          Questions
        </p>
        <h2 className="mt-5 text-4xl font-semibold leading-[1.05] tracking-[-0.045em] xs:text-5xl md:text-6xl">
          A few practical details.
        </h2>
      </div>

      <div className="mt-12 space-y-3 sm:mt-16">
        {FAQS.map(({ question, answer }) => (
          <details
            key={question}
            className="group rounded-2xl border border-violet-100 bg-violet-50/70 px-5 sm:px-7"
          >
            <summary className="flex cursor-pointer list-none items-center justify-between gap-5 py-5 text-left font-semibold marker:content-none sm:py-6 sm:text-lg [&::-webkit-details-marker]:hidden">
              {question}
              <ChevronDownIcon className="size-5 shrink-0 text-violet-600 transition-transform duration-200 group-open:rotate-180" />
            </summary>
            <p className="max-w-3xl pb-6 pr-2 leading-relaxed text-slate-600 sm:pr-8">
              {answer}
            </p>
          </details>
        ))}
      </div>
    </div>

    <div className="relative mx-auto mt-20 flex max-w-6xl flex-col items-center overflow-hidden rounded-[2rem] bg-slate-950 px-6 py-14 text-center text-white shadow-2xl shadow-violet-900/10 sm:mt-28 sm:rounded-[2.5rem] sm:px-12 sm:py-20">
      <div className="pointer-events-none absolute left-1/2 top-1/2 size-[32rem] -translate-x-1/2 -translate-y-1/2 rounded-full bg-fuchsia-600/20 blur-[100px]" />
      <div className="relative">
        <p className="text-sm font-semibold uppercase tracking-[0.16em] text-fuchsia-300">
          Gertrude Music
        </p>
        <h2 className="mx-auto mt-5 max-w-3xl text-4xl font-semibold leading-[1.05] tracking-[-0.045em] sm:text-5xl">
          The music you choose.
          <br />
          Nothing else.
        </h2>
        <p className="mx-auto mt-5 max-w-2xl leading-relaxed text-violet-100/60">
          A beautiful music app inside a boundary your family understands.
        </p>
        <AppStoreLink className="mt-8" />
        <p className="mt-6 text-xs leading-relaxed text-white/35">
          Apple Music subscription required. Apple Music is sold separately.
        </p>
      </div>
    </div>
  </section>
);

export default FaqBlock;

const FAQS: Array<{ question: string; answer: string }> = [
  {
    question: `Is Gertrude Music a separate app?`,
    answer: `Yes. Gertrude Music is the listener's app for iPhone and iPad. Parents choose the library separately from their account.`,
  },
  {
    question: `Can my child search the whole Apple Music catalog?`,
    answer: `No. Catalog search stays in the parent dashboard. The listener sees approved artists and albums, plus playlists they create from that music. You as the parent have the ability to choose whatever you want from the entire Apple Music catalog for your child to be able to listen to.`,
  },
  {
    question: `How much does it cost?`,
    answer: `The app is free to download. Listening requires Gertrude Medium at $5 per month or Gertrude Full. Gertrude Medium covers the whole family.`,
  },
  {
    question: `Do we still need Apple Music?`,
    answer: `You don't need the Apple Music app on your child's device (in fact, you shouldn't; that's why we made Gertrude Music!), but your child will need an Apple Music subscription to be able to use the app. This can be provided by an Apple Music family plan subscription.`,
  },
  {
    question: `How do we keep other music apps out?`,
    answer: `Remove or disable Apple's Music app and any other app that offers unrestricted catalog access on the child's device. Gertrude Music then becomes their music player.`,
  },
  {
    question: `What devices are supported?`,
    answer: `Gertrude Music is designed for iPhone and iPad and currently requires iOS or iPadOS 17 or later. Parents can approve music from any browser.`,
  },
];
