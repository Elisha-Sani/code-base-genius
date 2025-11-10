'use client';
import { useEffect, useState } from 'react';

export default function LogStream({ jobId }: { jobId: string }) {
  const [logs, setLogs] = useState<string[]>([]);

  useEffect(() => {
    const interval = setInterval(async () => {
      const res = await fetch(`/api/pipeline/logs/${jobId}`);
      if (res.ok) {
        const data = await res.json();
        setLogs(data.logs);
      }
    }, 3000);
    return () => clearInterval(interval);
  }, [jobId]);

  return (
    <div className="border rounded p-4 h-64 overflow-y-auto bg-gray-50 dark:bg-gray-800">
      {logs.map((line, i) => (
        <pre key={i} className="text-sm">{line}</pre>
      ))}
    </div>
  );
}