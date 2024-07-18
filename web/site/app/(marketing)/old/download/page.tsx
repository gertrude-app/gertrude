import React from 'react';
import type { NextPage } from 'next';
import * as seo from '@/lib/seo';

export const metadata = seo.createMetadata(
  `Download | Gertrude Internet Filter and Parental Controls`,
  seo.description(`Download Gertrude`),
);

const DownloadPage: NextPage = () => (
  <div className="flex justify-center items-center px-0 xs:px-6 sm:px-8 md:px-12 lg:px-20 py-20">
    <h1>Download: old</h1>
  </div>
);

export default DownloadPage;
