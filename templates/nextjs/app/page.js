export const dynamic = 'force-dynamic';
export default function Home() {
  return <main><h1>Homelab</h1><p>{process.env.APP_MESSAGE || 'Environnement prêt.'}</p></main>;
}
