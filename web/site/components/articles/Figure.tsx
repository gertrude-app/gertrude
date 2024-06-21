import React from 'react';

interface Props {
  src: string;
  alt?: string;
  caption: string;
}

const Figure: React.FC<Props> = ({ src, alt, caption }) => (
  <figure>
    <img src={src} alt={alt} />
    <figcaption>{caption}</figcaption>
  </figure>
);

export default Figure;
