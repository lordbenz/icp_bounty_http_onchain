import { useState, useEffect } from "react";
import { onchain_oracle_backend } from "declarations/onchain-oracle-backend";

function App() {
  const [priceData, setPriceData] = useState([]);
  const [fetching, setFetching] = useState(false);

  // Fetch and load price data
  const fetchPriceData = async () => {
    setFetching(true);
    try {
      // Fetch raw text response from the backend
      const rawData = await onchain_oracle_backend.get_btc_usd_exchange();
      
      // Parse the response into JSON
      const parsedData = JSON.parse(rawData);

      // Extract timestamp and closing price (index 0: timestamp, index 4: close price)
      const formattedData = parsedData.map(([timestamp, , , , closePrice]) => ({
        timestamp,
        price: closePrice,
      }));

      // Update state with the formatted data
      setPriceData(formattedData);
    } catch (error) {
      console.error("Error fetching price data:", error);
    } finally {
      setFetching(false);
    }
  };

  // Fetch data when the component mounts
  useEffect(() => {
    fetchPriceData();
  }, []);

  return (
    <main>
      <header>
        <h1>BTC-USD Price Oracle</h1>
      </header>
      <section>
        <button onClick={fetchPriceData} disabled={fetching}>
          {fetching ? "Fetching..." : "Fetch Latest Price"}
        </button>
        <table>
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Price (USD)</th>
            </tr>
          </thead>
          <tbody>
            {priceData.map(({ timestamp, price }, index) => (
              <tr key={index}>
                <td>{new Date(Number(timestamp) * 1000).toLocaleString()}</td>
                <td>${price.toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </main>
  );
}

export default App;
