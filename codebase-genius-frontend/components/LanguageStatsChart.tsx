'use client';
import { PieChart, Pie, Cell, Tooltip, Legend } from 'recharts';

export default function LanguageStatsChart({ stats }: { stats: { language: string; percentage: number }[] }) {
  const colors = ['#2563eb', '#16a34a', '#dc2626', '#9333ea', '#f59e0b'];

  return (
    <PieChart width={400} height={300}>
      <Pie
        data={stats}
        dataKey="percentage"
        nameKey="language"
        cx="50%"
        cy="50%"
        outerRadius={100}
        label
      >
        {stats.map((_, i) => (
          <Cell key={i} fill={colors[i % colors.length]} />
        ))}
      </Pie>
      <Tooltip />
      <Legend />
    </PieChart>
  );
}