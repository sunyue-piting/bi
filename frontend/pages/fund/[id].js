
import { useRouter } from 'next/router';
import { useEffect, useState } from 'react';

export default function FundDetail() {
  const router = useRouter();
  const { id } = router.query;
  const [fund, setFund] = useState(null);

  useEffect(() => {
    if (!id) return;
    fetch(`/api/funds?search=${id}`)
      .then(res => res.json())
      .then(data => setFund(data[0]));
  }, [id]);

  if (!fund) return <div>Loading...</div>;

  return (
    <div className="p-10">
      <h1 className="text-3xl font-bold mb-4">{fund.name}</h1>
      <p>Inception Date: {fund.inception_date}</p>
      <p>Fund AUM: ${fund.fund_aum} million</p>
      <p>Firm AUM: ${fund.firm_aum} million</p>
    </div>
  );
}
