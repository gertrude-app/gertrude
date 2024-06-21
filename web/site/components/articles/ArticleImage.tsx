import React from 'react';
import cx from 'classnames';

type Props = {
  src: string;
  small?: boolean;
  caption?: string;
  alt?: string;
};

const ArticleImage: React.FC<Props> = ({ src, caption, alt, small }) => (
  <div className={cx(`mt-8 flex flex-col items-center`, small && `max-w-lg mx-auto`)}>
    <img
      className="m-0 rounded-3xl border border-slate-300"
      src={`/docs/images/${src}`}
      alt={alt ?? caption ?? ``}
    />
    {caption && (
      <div
        className="mb-4 pt-2.5 text-center *text-[15px] italic text-slate-400 leading-tight"
        dangerouslySetInnerHTML={{ __html: caption }}
      />
    )}
  </div>
);

export default ArticleImage;
