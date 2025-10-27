import cx from 'classnames';
import React from 'react';

type Props = {
  src: string;
  small?: boolean;
  caption?: string;
  alt?: string;
  noBorder?: boolean;
};

const ArticleImage: React.FC<Props> = ({ src, caption, alt, small, noBorder }) => (
  <div className={cx(`mt-8 flex flex-col items-center`, small && `max-w-lg mx-auto`)}>
    <img
      className={cx(`m-0 rounded-3xl`, noBorder !== true && `border border-slate-300`)}
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
