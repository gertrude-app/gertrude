import React from 'react';

interface Props {
  quote: string;
  name?: string;
}

const SignupPageTestimonial: React.FC<Props> = ({ quote, name }) => {
  return (
    <div className="flex flex-col shadow-md shadow-stone-300/20 bg-stone-50 border border-stone-200 p-6 rounded-2xl gap-4">
      <p className="text-stone-800">{quote}</p>
      {name && <p className="text-stone-500 self-end text-xs -mb-2">{name}</p>}
    </div>
  );
};

export default SignupPageTestimonial;
