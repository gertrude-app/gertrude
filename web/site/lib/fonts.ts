/* eslint-disable */

import { Roboto } from 'next/font/google';
import localFont from 'next/font/local';

const robotoFont = Roboto({
  subsets: ['latin'], // eslint-disable-line
  weight: ['100', '300', '400', '500', '700', '900'], // eslint-disable-line
});

export const roboto = robotoFont.className;

const axiformaFont = localFont({
  src: [
    {
      path: '../public/fonts/axiforma/Axiforma-Regular.woff2',
      weight: '400',
      style: 'normal',
    },
    {
      path: '../public/fonts/axiforma/Axiforma-Medium.woff2',
      weight: '500',
      style: 'normal',
    },
    {
      path: '../public/fonts/axiforma/Axiforma-SemiBold.woff2',
      weight: '600',
      style: 'normal',
    },
    {
      path: '../public/fonts/axiforma/Axiforma-Bold.woff2',
      weight: '700',
      style: 'normal',
    },
    {
      path: '../public/fonts/axiforma/Axiforma-Italic.woff2',
      weight: '400',
      style: 'italic',
    },
    {
      path: '../public/fonts/axiforma/Axiforma-MediumItalic.woff2',
      weight: '500',
      style: 'italic',
    },
    {
      path: '../public/fonts/axiforma/Axiforma-SemiBoldItalic.woff2',
      weight: '600',
      style: 'italic',
    },
    {
      path: '../public/fonts/axiforma/axiforma-BoldItalic.woff2',
      weight: '700',
      style: 'italic',
    },
  ],
});

export const axiforma = axiformaFont.className;
