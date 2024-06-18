import React from 'react';
import cx from 'classnames';

const TestimonialsBlock: React.FC = () => (
  <section className="xl:px-8 bg-gradient-to-b from-violet-100 to-violet-500">
    <div className="bg-slate-900 px-4 xs:px-8 sm:px-12 md:px-20 2xl:px-28 pt-0 md:pt-12 xl:pt-28 pb-40 relative flex xl:flex-row flex-col justify-center items-center overflow-hidden gap-8 xl:gap-0 2xl:gap-12">
      <TestimonialCard
        name="Jason Henderson"
        placeOfWork="Friends Library Publishing"
        className="xl:-rotate-6"
      >
        I spent years trying out different parental control software for my four kids (on
        both Macs and PCs) and never found anything that made me feel peaceful and secure
        about my kids' online activities until I started using Gertrude.
      </TestimonialCard>
      <TestimonialCard
        name="Frank Artinian, MD"
        placeOfWork="Akron Children's Hospital"
        className="xl:-translate-y-8"
      >
        We have used Gertrude for our two children for the past few years and have found
        it to be absolutely the most secure product available. The app makes securing
        children online something manageable for us as middle-aged parents with typical
        computer skills.
      </TestimonialCard>
      <TestimonialCard
        name="Jared Henderson"
        placeOfWork="Gertrude"
        className="xl:rotate-6"
      >
        I take online safety very seriously. I needed a bulletproof mac internet filter
        for my kids. When I couldn't find anything up to my standards, I built Gertrude.
        I'm biased, but I think it's the best tool out there for mac website blocking and
        oversight with keylogging and screenshots.
      </TestimonialCard>
    </div>
  </section>
);

export default TestimonialsBlock;

interface TestimonialCardProps {
  name: string;
  placeOfWork: string;
  children: React.ReactNode;
  className?: string;
}

const TestimonialCard: React.FC<TestimonialCardProps> = ({
  name,
  placeOfWork,
  children,
  className,
}) => (
  <div
    className={cx(
      `bg-slate-800 p-8 xs:p-12 rounded-3xl flex flex-col items-center xl:shadow-xl shadow-black/20 2xl:shadow-none`,
      className,
    )}
  >
    <p className="text-violet-100 text-xl text-center">{children}</p>
    <h3 className="text-xl font-semibold bg-gradient-to-r to-fuchsia-300 from-violet-200 bg-clip-text text-transparent mt-4">
      {name}
    </h3>
    <h4 className="text-violet-300/60">{placeOfWork}</h4>
  </div>
);
