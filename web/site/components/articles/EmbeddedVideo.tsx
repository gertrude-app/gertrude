import React from 'react';

type Props = {
  videoId: string;
  title: string;
};

const EmbeddedVideo: React.FC<Props> = ({ videoId, title }) => (
  <div className="w-full bg-black my-8">
    <div className="pt-[56.27%] relative">
      <iframe
        className="absolute inset-0 w-full h-full"
        width="100%"
        height="100%"
        src={`https://www.youtube.com/embed/${videoId}?rel=0&autoplay=0`}
        title={title}
        frameBorder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope;"
        allowFullScreen
      />
    </div>
  </div>
);

export default EmbeddedVideo;
