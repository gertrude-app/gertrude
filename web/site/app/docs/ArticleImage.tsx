import React from 'react';

type Props = {
  src: string;
  caption?: string;
  alt?: string;
};

const ArticleImage: React.FC<Props> = ({ src, caption, alt }) => (
  <div className="mt-8 flex flex-col items-center">
    <div className="rounded-xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 p-px">
      <div className="rounded-xl bg-slate-900 p-5">
        <img
          className="m-0 rounded-md"
          src={`/docs/images/${src}`}
          alt={alt ?? caption ?? ``}
        />
      </div>
    </div>
    {caption && (
      <div
        className="mb-4 pt-2.5 text-center *text-[15px] italic text-slate-300 leading-tight"
        dangerouslySetInnerHTML={{ __html: caption }}
      />
    )}
  </div>
);

export default ArticleImage;
