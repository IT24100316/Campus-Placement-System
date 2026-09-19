import React from 'react';

interface FeatureCard {
  icon: string;
  title: string;
  description: string;
}

const features: FeatureCard[] = [
  {
    icon: 'hub',
    title: 'Semantic Skill Matching',
    description:
      'Deep evaluation of repositories, coursework, and problem-solving velocity beyond static resume keywords.',
  },
  {
    icon: 'description',
    title: 'AI CV Summarization',
    description:
      'Instantly transforms multi-page resumes and transcripts into clear, standardized executive briefs highlighting proven competencies.',
  },
  {
    icon: 'event_available',
    title: 'Automated Interview Scheduling',
    description:
      'Autonomous coordination that synchronizes academic calendars, exam schedules, and enterprise interviewer availability.',
  },
];

export const Features: React.FC = () => {
  return (
    <section id="features" className="max-w-7xl mx-auto px-6 py-24">
      <div className="max-w-2xl mb-16">
        <h2 className="font-display text-3xl font-bold text-slate-900 tracking-tight mb-3">
          Purpose-Built for Modern Recruitment
        </h2>
        <p className="text-base text-slate-600 leading-relaxed">
          Engineered to eliminate manual bottlenecks in high-volume campus drives and institutional
          placement offices.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {features.map((feature) => (
          <div
            key={feature.title}
            className="p-8 rounded-2xl border border-slate-200/80 bg-white hover:border-slate-300 hover:shadow-sm transition-all flex flex-col justify-between group"
          >
            <div>
              <div className="w-11 h-11 rounded-xl bg-blue-50 text-primary flex items-center justify-center mb-6 group-hover:scale-105 transition-transform">
                <span className="material-symbols-outlined text-[24px]">
                  {feature.icon}
                </span>
              </div>
              <h3 className="font-headline-sm text-lg font-bold text-slate-900 mb-2">
                {feature.title}
              </h3>
              <p className="text-sm text-slate-600 leading-relaxed">
                {feature.description}
              </p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
};
