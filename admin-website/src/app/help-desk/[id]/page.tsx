import { HelpDeskDetailPage } from '@/components/admin-pages';
export default function Page({ params }: { params: { id: string } }) {
  return <HelpDeskDetailPage id={params.id} />;
}

