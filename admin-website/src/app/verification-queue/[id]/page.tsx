import { VerificationDetailPage } from '@/components/admin-pages';
export default function Page({ params }: { params: { id: string } }) {
  return <VerificationDetailPage id={params.id} />;
}

