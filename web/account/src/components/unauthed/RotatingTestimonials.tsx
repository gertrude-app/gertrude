import { HStack, VStack } from '@gertrude/ui';
import React from 'react';
import SignupPageTestimonial from './SignupPageTestimonial';

export type Testimonial = {
  quote: string;
  name?: string;
};

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
    <VStack className="min-w-0 flex-1">
      <VStack
        className="testimonial-marquee"
        style={
          {
            '--testimonial-marquee-duration': duration,
            animationDelay: `${columnIndex * -28}s`,
          } as MarqueeStyle
        }
      >
        {marqueeIterations.map((iteration) => (
          <VStack
            key={iteration}
            ref={iteration === 0 ? contentRef : undefined}
            gap={3}
            className="shrink-0 pb-3"
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
          </VStack>
        ))}
      </VStack>
    </VStack>
  );
};

interface Props {
  testimonials: Testimonial[];
}

const RotatingTestimonials: React.FC<Props> = ({ testimonials }) => {
  const testimonialColumns = splitIntoBuckets(testimonials, 3);

  return (
    <div className="relative mt-10 min-h-0 flex-1 w-[120%] overflow-hidden [mask-image:linear-gradient(to_bottom,transparent,black_10%,black)]">
      <HStack
        align="stretch"
        gap={3}
        className="absolute -left-30 right-30 -top-16 bottom-0 origin-bottom-left rotate-12"
      >
        {testimonialColumns.map((column, columnIndex) => (
          <TestimonialColumn
            key={columnIndex}
            column={column}
            columnIndex={columnIndex}
          />
        ))}
      </HStack>
    </div>
  );
};

export default RotatingTestimonials;
