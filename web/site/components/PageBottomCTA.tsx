import { ArrowRightIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import Button from './Button';
import Logo from './Logo';
import { PARENTS_APP_URL } from '@/lib/urls';

interface Props {
  clickId: string;
}

const PageBottomCTA: React.FC<Props> = ({ clickId }) => (
  <div className="mt-16 p-8 sm:p-12 bg-gradient-to-br from-violet-500 to-fuchsia-500 rounded-3xl flex flex-col items-center">
    <Link href="/">
      <Logo type="inverted" />
    </Link>
    <p className="mt-8 text-center text-white sm:text-lg">
      The Gertrude mac app helps you <b>protect your kids</b> online with{` `}
      <b>strict internet filtering</b> that you can manage from your{` `}
      <b>own computer or phone,</b> plus remote monitoring of screenshots and keylogging.
      $10/mo, with a 21 day free trial.
    </p>
    <Button
      type="link"
      id={clickId}
      href={`${PARENTS_APP_URL}/signup`}
      color="primary"
      inverted
      className="mt-8"
      Icon={ArrowRightIcon}
    >
      Start free trial
    </Button>
  </div>
);

export default PageBottomCTA;
