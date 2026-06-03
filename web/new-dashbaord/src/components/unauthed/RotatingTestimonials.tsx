import React from 'react';
import SignupPageTestimonial from './SignupPageTestimonial';
import { quotes } from '#/lib/data';

type Testimonial = (typeof quotes)[number];
type MarqueeStyle = React.CSSProperties & {
  '--testimonial-marquee-duration': string;
};

const splitIntoBuckets = <T,>(items: T[], bucketCount: number): T[][] => {
  let start = 0;
  const baseSize = Math.floor(items.length / bucketCount);
  const extraItems = items.length % bucketCount;

  return Array.from({ length: bucketCount }, (_, bucketIndex) => {
    const size = baseSize + (bucketIndex < extraItems ? 1 : 0);
    const bucket = items.slice(start, start + size);
    start += size;
    return bucket;
  });
};

const testimonialColumns = splitIntoBuckets(quotes, 3);
const testimonialColumnSpeeds = [12, 16, 14] as const;
const marqueeIterations = [0, 1, 2, 3] as const;

interface TestimonialColumnProps {
  column: Testimonial[];
  columnIndex: number;
}

const TestimonialColumn: React.FC<TestimonialColumnProps> = ({ column, columnIndex }) => {
  const contentRef = React.useRef<HTMLDivElement>(null);
  const [duration, setDuration] = React.useState(`${88 - columnIndex * 12}s`);

  React.useEffect(() => {
    const element = contentRef.current;

    if (!element) {
      return;
    }

    const speed = testimonialColumnSpeeds[columnIndex] ?? testimonialColumnSpeeds[0];
    const updateDuration = (): void => {
      const nextDuration = `${Math.round((element.offsetHeight / speed) * 10) / 10}s`;
      setDuration((currentDuration) =>
        currentDuration === nextDuration ? currentDuration : nextDuration,
      );
    };

    updateDuration();

    if (typeof ResizeObserver === `undefined`) {
      return;
    }

    const resizeObserver = new ResizeObserver(updateDuration);
    resizeObserver.observe(element);

    return () => resizeObserver.disconnect();
  }, [columnIndex]);

  return (
    <div className="min-w-0 flex-1">
      <div
        className="testimonial-marquee flex flex-col"
        style={
          {
            '--testimonial-marquee-duration': duration,
            animationDelay: `${columnIndex * -28}s`,
          } as MarqueeStyle
        }
      >
        {marqueeIterations.map((iteration) => (
          <div
            key={iteration}
            ref={iteration === 0 ? contentRef : undefined}
            className="flex shrink-0 flex-col gap-3 pb-3"
          >
            {column.map((testimonial, testimonialIndex) => (
              <div
                key={`${iteration}-${testimonialIndex}`}
                className="shrink-0"
                aria-hidden={iteration > 0}
              >
                <SignupPageTestimonial {...testimonial} />
              </div>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
};

const RotatingTestimonials: React.FC = () => (
  <div className="relative mt-10 min-h-0 flex-1 w-[120%] overflow-hidden [mask-image:linear-gradient(to_bottom,transparent,black_10%,black)]">
    <div className="absolute -left-30 right-30 -top-16 bottom-0 flex origin-bottom-left rotate-12 gap-3">
      {testimonialColumns.map((column, columnIndex) => (
        <TestimonialColumn key={columnIndex} column={column} columnIndex={columnIndex} />
      ))}
    </div>
  </div>
);

export default RotatingTestimonials;
