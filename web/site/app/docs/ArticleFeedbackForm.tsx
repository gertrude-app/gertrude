import React from 'react';

interface Props {
  name: string;
}

const ArticleFeedbackForm: React.FC<Props> = ({ name }) => (
  <div className="mt-16">
    <div className="flex gap-4">
      <span className="text-4xl" role="img" aria-label="thinking emoji">
        🤔
      </span>
      <p className="mb-3 mt-0 italic leading-snug">
        Questions? Comments? Stuck trying to do some step of this tutorial? Let us know by
        submitting the form below, and we'll try to help!
      </p>
    </div>
    <form
      className="pl-12 flex flex-col space-y-4 text-white max-w-2xl pr-2"
      data-netlify="true"
      name={name}
      method="POST"
    >
      <input type="hidden" name="form-name" value={name} />
      <div className="lg:flex lg:space-x-4">
        <fieldset className="lg:w-1/2">
          <label className="block text-slate-300" htmlFor="name">
            Name:
          </label>
          <input
            className="bg-slate-600 text-white rounded-md w-full max-w-sm"
            type="text"
            name="name"
            id="name"
            required
          />
        </fieldset>
        <fieldset className="lg:w-1/2 mt-4 lg:mt-0">
          <label className="block text-slate-300" htmlFor="email">
            Email:
          </label>
          <input
            className="bg-slate-600 text-white rounded-md w-full max-w-sm"
            type="email"
            name="email"
            id="email"
            placeholder="you@example.com"
            required
          />
        </fieldset>
      </div>
      <fieldset>
        <label className="block text-slate-300" htmlFor="message">
          Message:
        </label>
        <textarea
          className="bg-slate-600 text-white rounded-md w-full"
          name="message"
          id="message"
          rows={5}
          required
        />
      </fieldset>
      <fieldset>
        <button className="bg-slate-600 rounded-lg px-5 py-0.5" type="submit">
          Submit &rarr;
        </button>
      </fieldset>
    </form>
  </div>
);

export default ArticleFeedbackForm;
