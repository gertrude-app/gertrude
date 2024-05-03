import React from 'react';
import { RatIcon } from 'lucide-react';
import Link from 'next/link';
import type { NextPage } from 'next';
import MainFooter from '@/components/MainFooter';
import MainHeader from '@/components/MainHeader';

const NotFound: NextPage = () => (
  <html>
    <body className="min-h-screen flex flex-col">
      <MainHeader theme="white" />
      <main className="flex-grow flex px-12 sm:px-20 py-20 flex-col items-center justify-center">
        <div className="bg-violet-100 rounded-full w-24 h-24 flex justify-center items-center">
          <RatIcon size={50} className="text-violet-700" />
        </div>
        <h1 className="mt-8 text-5xl font-semibold font-axiforma">Uh-oh!</h1>
        <p className="text-xl text-slate-500 mt-4 max-w-md text-center">
          Looks like that page doesn't exist.{` `}
          <Link href="/" className="text-violet-500 underline">
            Click here
          </Link>
          {` `}
          to go to our homepage.
        </p>
      </main>
      <MainFooter />
    </body>
  </html>
);

export default NotFound;
