import React from 'react';

interface MetricItem {
  value: string;
  label: string;
}

const metrics: MetricItem[] = [
  { value: '36 Hours', label: 'Average time to offer' },
  { value: '94.2%', label: '1st-year retention rate' },
  { value: '120K+', label: 'Verified candidate profiles' },
  { value: '0 Bias', label: 'Standardized blind evaluations' },
];

export const Metrics: React.FC = () => {
  return (
    <section id="metrics" className="border-y border-slate-100 bg-slate-50/50 py-12">
      <div className="max-w-7xl mx-auto px-6">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-12">
          {metrics.map((item) => (
            <div key={item.label} className="flex flex-col">
              <div className="font-display text-3xl md:text-4xl font-extrabold text-slate-900 mb-1 tracking-tight">
                {item.value}
              </div>
              <div className="text-xs font-medium text-slate-500 tracking-normal">
                {item.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
