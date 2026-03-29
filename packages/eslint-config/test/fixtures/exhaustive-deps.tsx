// Fixture: triggers react-hooks/exhaustive-deps
import { useEffect, useState } from 'react';

export function Component() {
  const [count, setCount] = useState(0);
  // eslint-disable-next-line react-hooks/rules-of-hooks — this is intentionally broken for testing
  useEffect(() => {
    console.warn(count);
  }, []); // missing `count` in deps array
  return null;
}
