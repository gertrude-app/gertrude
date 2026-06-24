import { XIcon } from 'lucide-react';
import React from 'react';
import Button from './Button';

type Props = {
  videoId: string;
  onDismiss(): unknown;
};

const VideoModal: React.FC<Props> = ({ onDismiss, videoId }) => (
  <div
    className="fixed flex justify-center items-center inset-0 z-50 bg-violet-900/95"
    onClick={onDismiss}
  >
    <div className="w-full max-w-[1820px] bg-black md:mx-4 lg:mx-6">
      <div className="pt-[56.27%] relative">
        <iframe
          className="absolute inset-0 w-full h-full"
          width="100%"
          height="100%"
          src={`https://www.youtube.com/embed/${videoId}?rel=0&autoplay=1`}
          title="Gertrude video"
          frameBorder="0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope;"
          allowFullScreen
        />
      </div>
    </div>
    <Button
      className="antialiased absolute top-0 right-0 m-7"
      color="secondary"
      inverted
      onClick={onDismiss}
      type="button"
      size="sm"
      Icon={XIcon}
    >
      Close
    </Button>
  </div>
);

export default VideoModal;
