'use client';

import React, { useState } from 'react';
import Turnstile from 'react-turnstile';
import FancyLink from '@/components/FancyLink';
import * as env from '@/lib/env';

interface Props {
  name: string;
  lang: `en` | `es`;
}

const ArticleFeedbackForm: React.FC<Props> = ({ name, lang }) => {
  const [turnstileToken, setTurnstileToken] = useState<string>(``);
  const { formsEndpoint, turnstileSitekey } = env.getPublicVars();
  return (
    <div className="mt-24">
      <div className="flex gap-4">
        <span className="text-4xl" role="img" aria-label="thinking emoji">
          🤔
        </span>
        <p className="mb-3 mt-0 italic leading-snug">
          {lang === `en`
            ? `Questions? Comments? Stuck trying to do some step of this tutorial? Let us know by
        submitting the form below, and we'll try to help!`
            : `¿Preguntas? ¿Comentarios? ¿Te quedaste atascado intentando realizar algún paso de este tutorial? Háznoslo saber enviando el siguiente formulario y ¡haremos lo posible por ayudarte!`}
        </p>
      </div>
      <form
        className="pl-12 flex flex-col space-y-4 text-white max-w-2xl pr-2"
        name={name}
        method="POST"
        action={formsEndpoint}
      >
        <Turnstile
          sitekey={turnstileSitekey}
          refreshExpired="auto"
          onVerify={setTurnstileToken}
        />
        <input type="hidden" name="form" value={name} />
        <input type="hidden" name="turnstileToken" value={turnstileToken} />
        <div className="lg:flex lg:space-x-4">
          <fieldset className="lg:w-1/2">
            <label className="block text-slate-600 ml-3" htmlFor="name">
              {lang === `en` ? `Name:` : `Nombre:`}
            </label>
            <input
              className="bg-slate-100 text-slate-800 rounded-xl w-full max-w-sm border-none placeholder-slate-300"
              placeholder="John Doe"
              type="text"
              name="name"
              id="name"
              required
            />
          </fieldset>
          <fieldset className="lg:w-1/2 mt-4 lg:mt-0">
            <label className="block text-slate-600 ml-3" htmlFor="email">
              {lang === `en` ? `Email:` : `Correo electrónico:`}
            </label>
            <input
              className="bg-slate-100 text-slate-800 rounded-xl w-full max-w-sm border-none placeholder-slate-300"
              type="email"
              name="email"
              id="email"
              placeholder="you@example.com"
              required
            />
          </fieldset>
        </div>
        <fieldset>
          <label className="block text-slate-600 ml-3" htmlFor="message">
            {lang === `en` ? `Message:` : `Mensaje:`}
          </label>
          <textarea
            className="bg-slate-100 text-slate-800 rounded-xl w-full border-none placeholder-slate-300"
            name="message"
            id="message"
            rows={5}
            required
          />
        </fieldset>
        <fieldset>
          <FancyLink type="submit" color="primary">
            {lang === `en` ? `Submit` : `Enviar`} →
          </FancyLink>
        </fieldset>
      </form>
    </div>
  );
};

export default ArticleFeedbackForm;
