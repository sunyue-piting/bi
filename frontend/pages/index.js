
import { useState, useEffect } from 'react';
import Link from 'next/link';

export default function Home() {
  const [funds, setFunds] = useState([]);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetch("/api/funds")
      .then(res => res.json())
      .then(data => setFunds(data));
  }, []);

  const handleSearch = () => {
    fetch(`/api/funds?search=${search}`)
      .then(res => res.json())
      .then(data => setFunds(data));
  };

  return (
    <div className="p-10">
      <h1 className="text-3xl font-bold mb-4">Fund Search</h1>
      <input className="border p-2 mr-2" value={search} onChange={e => setSearch(e.target.value)} />
      <button onClick={handleSearch} className="bg-blue-500 text-white p-2">Search</button>
      <ul className="mt-6">
        {funds.map(fund => (
          <li key={fund.id} className="mb-2">
            <Link href={`/fund/${fund.id}`}>{fund.name}</Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
