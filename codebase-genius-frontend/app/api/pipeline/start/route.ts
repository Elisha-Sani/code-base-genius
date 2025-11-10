// app/api/pipeline/start/route.ts
import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  const { repo_url } = (await req.json()) as { repo_url: string };

  const res = await fetch(`${process.env.NEXT_PUBLIC_API_BASE}/pipeline/start`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ repo_url }),
    cache: 'no-store',
  });

  if (!res.ok) {
    return NextResponse.json({ error: 'Failed to start pipeline' }, { status: 500 });
  }

  const data = (await res.json()) as { jobId: string };
  return NextResponse.json({ jobId: data.jobId });
}
