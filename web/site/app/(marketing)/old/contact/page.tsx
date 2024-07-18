import React from 'react';
import type { NextPage } from 'next';
import * as seo from '@/lib/seo';

export const metadata = seo.createMetadata(
  `Contact | Gertrude Internet Filter and Parental Controls`,
  seo.description(`Contact us`),
);

const ContactPage: NextPage = () => (
  <div className="flex justify-center items-center px-0 xs:px-8 py-8 sm:px-12 sm:py-12 md:px-20 md:py-20">
    <h1>Contact Page: old</h1>
  </div>
);

export default ContactPage;
