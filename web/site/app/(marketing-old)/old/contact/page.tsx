import React from 'react';
import type { NextPage } from 'next';
import ContactForm from './OldContactForm';
import * as seo from '@/lib/seo';

export const metadata = seo.createMetadata(
  `Contact | Gertrude Internet Filter and Parental Controls`,
  seo.description(`Contact us`),
);

const ContactPage: NextPage = () => <ContactForm />;

export default ContactPage;
