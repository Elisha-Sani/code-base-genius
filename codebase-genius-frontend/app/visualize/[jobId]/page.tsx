import FileTreeExplorer from '@/components/FileTreeExplorer';
import LanguageStatsChart from '@/components/LanguageStatsChart';
import MermaidDiagram from '@/components/MermaidDiagram';
import ErrorBoundary from '@/components/ErrorBoundary';

async function getVisuals(jobId: string) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_API_BASE}/artifacts/visuals/${jobId}`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch visuals');
  return res.json();
}

export default async function VisualizePage({ params }: { params: { jobId: string } }) {
  const data = await getVisuals(params.jobId);

  return (
    <div className="space-y-8">
      <h2 className="text-2xl font-bold">Visualizations</h2>

      <section>
        <h3 className="text-xl font-semibold mb-2">File Tree</h3>
        <ErrorBoundary>
          <FileTreeExplorer tree={data.fileTree} />
        </ErrorBoundary>
      </section>

      <section>
        <h3 className="text-xl font-semibold mb-2">Language Stats</h3>
        <ErrorBoundary>
          <LanguageStatsChart stats={data.languageStats} />
        </ErrorBoundary>
      </section>

      <section>
        <h3 className="text-xl font-semibold mb-2">Architecture Diagram</h3>
        <ErrorBoundary fallback={<p className="text-red-600">Diagram failed to render.</p>}>
          <MermaidDiagram diagram={data.diagram} />
        </ErrorBoundary>
      </section>
    </div>
  );
}