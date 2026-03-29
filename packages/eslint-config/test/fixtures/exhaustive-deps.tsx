// Fixture: triggers react-hooks/exhaustive-deps
import { useEffect, useState } from 'react';

export function Component() {
  const [count, setCount] = useState(0);
  // This useEffect is intentionally missing `count` in the deps array for testing
  useEffect(() => {
    console.warn(count);
  }, []); // missing `count` in deps array
  return null;
}
