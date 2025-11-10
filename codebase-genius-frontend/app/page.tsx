'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';

export default function HomePage() {
  const [url, setUrl] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const validateUrl = (value: string) => {
    const regex = /^https:\/\/github\.com\/[\w.-]+\/[\w.-]+$/;
    return regex.test(value);
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);

    if (!validateUrl(url)) {
      const msg = 'Please enter a valid GitHub repository URL.';
      setError(msg);
      toast.error(msg);
      return;
    }

    setLoading(true);
    try {
      const res = await fetch('/api/pipeline/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ repo_url: url }),
      });

      if (!res.ok) {
        const msg = 'Failed to start pipeline';
        toast.error(msg);
        throw new Error(msg);
      }

      const data: { jobId: string } = await res.json();
      toast.success('Pipeline started successfully!');
      router.push(`/pipeline/${data.jobId}`);
    } catch (err) {
      const msg = (err as Error).message || 'Unexpected error';
      setError(msg);
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh]">
      <h2 className="text-2xl font-bold mb-6">Start Codebase Genius</h2>
      <form onSubmit={handleSubmit} className="w-full max-w-md space-y-4">
        <input
          type="text"
          placeholder="Enter GitHub repo URL"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          className="w-full px-4 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800"
        />
        {error && <p className="text-red-500 text-sm">{error}</p>}
        <button
          type="submit"
          disabled={loading}
          className="w-full bg-blue-600 text-white py-2 rounded-md hover:bg-blue-700 disabled:opacity-50"
        >
          {loading ? 'Starting...' : 'Start Pipeline'}
        </button>
      </form>
    </div>
  );
}