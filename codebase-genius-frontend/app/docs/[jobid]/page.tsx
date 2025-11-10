import MarkdownViewer from '@/components/MarkdownViewer';
import DocTOC from '@/components/DocTOC';
import DocToolbar from '@/components/DocToolbar';

async function getDocs(jobId: string) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_API_BASE}/artifacts/docs/${jobId}`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch docs');
  const data = await res.text(); // Markdown content
  return data;
}

export default async function DocsPage({ params }: { params: { jobId: string } }) {
  const content = await getDocs(params.jobId);

  return (
    <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
      <aside className="md:col-span-1">
        <DocTOC content={content} />
      </aside>
      <section className="md:col-span-3 space-y-4">
        <DocToolbar jobId={params.jobId} content={content} />
        <MarkdownViewer content={content} />
      </section>
    </div>
  );
}