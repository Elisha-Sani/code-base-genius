'use client';

import toast from 'react-hot-toast';

export default function DocToolbar({ jobId, content }: { jobId: string; content: string }) {
  const handleExport = () => {
    try {
      const blob = new Blob([content], { type: 'text/markdown' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${jobId}.md`;
      a.click();
      URL.revokeObjectURL(url);
      toast.success('Documentation exported!');
    } catch {
      toast.error('Export failed');
    }
  };

  const handleCopyLink = () => {
    try {
      navigator.clipboard.writeText(window.location.href);
      toast.success('Link copied to clipboard');
    } catch {
      toast.error('Failed to copy link');
    }
  };

  return (
    <div className="flex space-x-4 mb-4">
      <button onClick={handleCopyLink} className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700">
        Copy Link
      </button>
      <button onClick={handleExport} className="px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700">
        Export Markdown
      </button>
    </div>
  );
}