
import { useState, useEffect } from 'react';
import Link from 'next/link';

export default function Home() {
  const [funds, setFunds] = useState([]);

  useEffect(() => {
    fetch("/api/funds").then(res => res.json()).then(setFunds);
  }, []);

  return (
    <div className="p-10">
      <h1 className="text-3xl font-bold mb-4">Fund List</h1>
      <ul>
        {funds.map(fund => (
          <li key={fund.id} className="mb-2">
            <Link href={`/fund/${fund.id}`}>{fund.name}</Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
