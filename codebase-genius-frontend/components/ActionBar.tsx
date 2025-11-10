'use client';

import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';

export default function ActionBar({ jobId }: { jobId: string }) {
  const router = useRouter();

  const handleAction = async (action: 'retry' | 'cancel') => {
    try {
      const res = await fetch(`/api/pipeline/${action}/${jobId}`, { method: 'POST' });
      if (!res.ok) {
        const msg = `Pipeline ${action} failed`;
        toast.error(msg);
        throw new Error(msg);
      }
      toast.success(`Pipeline ${action}ed successfully`);
      router.refresh();
    } catch (err) {
      toast.error((err as Error).message || 'Unexpected error');
    }
  };

  return (
    <div className="flex space-x-4">
      <button
        onClick={() => handleAction('retry')}
        className="px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600"
      >
        Retry
      </button>
      <button
        onClick={() => handleAction('cancel')}
        className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
      >
        Cancel
      </button>
      <button
        onClick={() => router.push(`/docs/${jobId}`)}
        className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
      >
        View Docs
      </button>
      <button
        onClick={() => router.push(`/visualize/${jobId}`)}
        className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
      >
        Visualize
      </button>
    </div>
  );
}