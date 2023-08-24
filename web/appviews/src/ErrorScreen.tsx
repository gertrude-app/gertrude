import React from 'react';
import ErrorBlock from './ErrorBlock';
import { type Props } from './ErrorBlock';

const ErrorScreen: React.FC<Props> = (props) => (
  <div className="min-h-screen flex justify-center bg-white dark:bg-slate-900 items-center px-12">
    <ErrorBlock {...props} />
  </div>
);

export default ErrorScreen;
