import StageStatusList from '@/components/StageStatusList';
import LogStream from '@/components/LogStream';
import ActionBar from '@/components/ActionBar';

async function getPipelineData(jobId: string) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_API_BASE}/pipeline/status/${jobId}`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch pipeline status');
  return res.json();
}

export default async function PipelinePage({ params }: { params: { jobId: string } }) {
  const data = await getPipelineData(params.jobId);

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold">Pipeline Dashboard</h2>
      <StageStatusList stages={data.pipeline_stages} />
      <LogStream jobId={params.jobId} />
      <ActionBar jobId={params.jobId} />
    </div>
  );
}