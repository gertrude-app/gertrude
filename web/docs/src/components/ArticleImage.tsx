import React from 'react';

type Props = {
  src: string;
  caption?: string;
};

const ArticleImage: React.FC<Props> = ({ src, caption }) => (
  <div className="mt-8 flex flex-col items-center">
    <div className="rounded-xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 p-px">
      <div className="rounded-xl bg-slate-900 p-5">
        <img className="m-0 rounded-md" src={`/images/${src}`} alt={caption ?? ``} />
      </div>
    </div>
    {caption && (
      <div className="mb-4 pt-2 text-center text-sm font-semibold italic text-slate-300">
        {caption}
      </div>
    )}
  </div>
);

export default ArticleImage;
