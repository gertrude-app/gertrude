import React from 'react';
import { Logo } from '@shared/components';
import ContactForm from 'components/ContactForm';
import type { NextPage } from 'next';

export const metadata = {
  title: `Contact | Gertrude Internet Filter and Parental Controls`,
  description: `TODO: Add description`,
  openGraph: {
    title: `Contact | Gertrude Internet Filter and Parental Controls`,
    description: `TODO: Add description`,
    images: [
      {
        url: `/og-images/main.jpg`,
        width: 1200,
        height: 630,
        alt: `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`,
      },
    ],
  },
};

const ContactPage: NextPage = () => (
  <div className="flex justify-center items-center px-0 xs:px-8 py-8 sm:px-12 sm:py-12 md:px-20 md:py-20">
    <div className="bg-white p-8 xs:p-12 sm:p-16 lg:p-20 rounded-[40px] flex flex-col relative overflow-hidden">
      <Logo iconOnly className="absolute -top-40 right-6 opacity-10" size={400} />
      <Logo iconOnly className="absolute -bottom-56 left-6 opacity-10" size={400} />
      <h1 className="font-axiforma text-4xl font-semibold self-center lg:self-start relative">
        Contact us
      </h1>
      <p className="text-xl mt-3 text-slate-500 max-w-2xl self-center lg:self-start text-center lg:text-left relative">
        Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint
        consectetur cupidatat.
      </p>
      <ContactForm />
    </div>
  </div>
);

export default ContactPage;
