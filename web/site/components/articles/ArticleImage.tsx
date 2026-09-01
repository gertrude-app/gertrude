import cx from 'classnames';
import React from 'react';

type Props = {
  src: string;
  small?: boolean;
  width?: number;
  caption?: string;
  alt?: string;
  noBorder?: boolean;
};

const ArticleImage: React.FC<Props> = ({ src, caption, alt, small, width, noBorder }) => (
  <figure className="not-prose relative isolate mb-12 mt-9">
    <div
      className={cx(
        `mx-auto flex flex-col items-center`,
        small ? `max-w-lg` : `max-w-4xl`,
      )}
    >
      <div>
        <div className="rounded-[24px] border border-white bg-white/50 p-2 shadow-md shadow-violet-950/5">
          <img
            style={width ? { width: `${width}px` } : undefined}
            className={cx(
              `m-0 rounded-2xl bg-white`,
              width ? `max-w-full` : `w-full`,
              noBorder !== true && `shadow shadow-stone-950/10`,
            )}
            src={`/docs/images/${src}`}
            alt={alt ?? caption ?? ``}
          />
        </div>
      </div>
      {caption && (
        <figcaption
          className="mt-4 max-w-2xl text-center text-sm font-medium leading-5 text-violet-950/80 [&_a]:font-semibold [&_a]:text-violet-700 [&_a]:underline [&_a]:decoration-violet-300 [&_a]:underline-offset-2"
          dangerouslySetInnerHTML={{ __html: caption }}
        />
      )}
    </div>
  </figure>
);

export default ArticleImage;
