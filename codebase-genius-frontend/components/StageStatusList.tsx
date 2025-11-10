'use client';

export default function StageStatusList({ stages }: { stages: Record<string, string> }) {
  const colorMap: Record<string, string> = {
    success: 'bg-green-600',
    failed: 'bg-red-600',
    running: 'bg-blue-600',
    queued: 'bg-gray-400',
  };

  return (
    <div className="flex space-x-4">
      {Object.entries(stages).map(([name, status]) => (
        <div key={name} className={`px-3 py-1 rounded text-white ${colorMap[status]}`}>
          {name}: {status}
        </div>
      ))}
    </div>
  );
}