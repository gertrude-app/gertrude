import React from 'react';
import { CheckIcon } from './shared';

const MoreFeaturesBlock: React.FC = () => (
  <section className="bg-slate-900 pt-16 pb-20 sm:pt-24 sm:pb-28 lg:pt-28 lg:pb-32">
    <div className="max-w-7xl mx-auto px-4 xs:px-8 sm:px-12 md:px-20">
      <div className="text-center mb-12">
        <div className="inline-flex items-center gap-2 bg-violet-500/20 px-3 py-1.5 rounded-full text-violet-300 text-sm font-medium mb-6">
          <svg
            className="size-4"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
          And More
        </div>
        <h2 className="text-3xl xs:text-4xl md:text-5xl font-bold text-white mb-6 leading-tight">
          Even More Protection...
        </h2>
        <p className="text-lg xs:text-xl text-slate-300 leading-relaxed max-w-3xl mx-auto">
          Gertrude is constantly evolving to keep up with new iOS features and loopholes.
          Here&apos;s what else you can block:
        </p>
      </div>
      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-12">
        {[
          {
            title: `AI Image Lookup`,
            description: `Block AI-powered image recognition and lookup features in the Photos app`,
          },
          {
            title: `WhatsApp Content`,
            description: `Block non-chat content in WhatsApp like Stories and Channels`,
          },
          {
            title: `App Store Images`,
            description: `Hide promotional images and screenshots across all App Store surfaces`,
          },
          {
            title: `Support Link Backdoors`,
            description: `Block access to web browsing through Apple support website links`,
          },
          {
            title: `Auto-Updates`,
            description: `New blocks added automatically as loopholes are discovered`,
          },
          {
            title: `iOS Version Support`,
            description: `Updated regularly to support new iOS releases and features`,
          },
        ].map((feature, i) => (
          <div
            key={i}
            className="bg-slate-800/50 border border-slate-700/50 rounded-2xl p-5"
          >
            <div className="flex items-start gap-3">
              <div className="shrink-0 size-8 rounded-lg bg-violet-500/20 flex items-center justify-center mt-0.5">
                <CheckIcon className="size-4 text-violet-400" />
              </div>
              <div>
                <h3 className="text-white font-semibold mb-1">{feature.title}</h3>
                <p className="text-slate-400 text-sm leading-relaxed">
                  {feature.description}
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>
      <div className="bg-gradient-to-r from-violet-500/10 via-fuchsia-500/10 to-violet-500/10 border border-violet-500/20 rounded-2xl p-6 sm:p-8">
        <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
          <div className="shrink-0">
            <div className="size-12 rounded-xl bg-gradient-to-br from-violet-500 to-fuchsia-500 flex items-center justify-center">
              <svg
                className="size-6 text-white"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth={2}
              >
                <circle cx="12" cy="12" r="3" />
                <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-2 2 2 2 0 01-2-2v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 01-2-2 2 2 0 012-2h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 010-2.83 2 2 0 012.83 0l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 012-2 2 2 0 012 2v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 0 2 2 0 010 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 012 2 2 2 0 01-2 2h-.09a1.65 1.65 0 00-1.51 1z" />
              </svg>
            </div>
          </div>
          <div className="text-center sm:text-left">
            <h3 className="text-xl sm:text-2xl font-bold text-white mb-2">
              Fully Configurable
            </h3>
            <p className="text-slate-300 leading-relaxed">
              Every blocking feature can be individually enabled or disabled. Customize
              Gertrude to match your family&apos;s needs&mdash;block everything, or just
              the specific loopholes that concern you.
            </p>
          </div>
        </div>
      </div>
    </div>
  </section>
);

export default MoreFeaturesBlock;
