import React from 'react';
import type { NextPage } from 'next';
import { createMetadata } from '@/lib/seo';

export const metadata = createMetadata(
  `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`,
  `Protect your kids online with easy-to-use Mac internet filtering, internet blocking, and mac keylogging`,
);

const HomePage: NextPage = () => (
  <main>
    <h1>Homepage: So very old</h1>
  </main>
);

export default HomePage;
