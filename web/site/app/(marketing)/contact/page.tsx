import { Logo } from '@shared/components';
import React from 'react';
import type { NextPage } from 'next';
import ContactForm from '@/components/ContactForm';
import * as seo from '@/lib/seo';

export const metadata = seo.createMetadata(
  `Contact | Gertrude Internet Filter and Parental Controls`,
  seo.description(`Contact us`),
);

const ContactPage: NextPage = () => (
  <div className="flex justify-center items-center px-0 xs:px-8 py-8 sm:px-12 sm:py-12 md:px-20 md:py-20">
    <div className="bg-white p-8 xs:p-12 sm:p-16 lg:p-20 rounded-[40px] flex flex-col relative overflow-hidden">
      <Logo iconOnly className="absolute -top-40 right-6 opacity-10" size={400} />
      <Logo iconOnly className="absolute -bottom-56 left-6 opacity-10" size={400} />
      <h1 className="text-4xl font-semibold self-center lg:self-start relative">
        Contact us
      </h1>
      <p className="text-xl mt-3 text-slate-500 max-w-2xl self-center lg:self-start text-center lg:text-left relative">
        Have a question or need help? Fill out the form below and we’ll get back to you in
        a jiffy.
      </p>
      <ContactForm />
    </div>
  </div>
);

export default ContactPage;
