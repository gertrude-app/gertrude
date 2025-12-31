import React from 'react';

interface SectionProps {
  title: string;
  children: React.ReactNode;
}

const Section: React.FC<SectionProps> = ({ title, children }) => (
  <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
    <div className="px-6 py-4 border-b border-slate-100">
      <h2 className="font-display font-semibold text-slate-900 text-lg">{title}</h2>
    </div>
    <div className="p-6">{children}</div>
  </section>
);

export default Section;
