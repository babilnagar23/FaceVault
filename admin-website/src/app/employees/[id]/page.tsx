import { EmployeeProfilePage } from '@/components/admin-pages';
export default function Page({ params }: { params: { id: string } }) {
  return <EmployeeProfilePage id={params.id} />;
}

