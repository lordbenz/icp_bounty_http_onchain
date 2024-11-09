import React, { useState, useEffect } from "react";
import { onchain_oracle_backend } from "../../declarations/onchain-oracle-backend";

interface PriceData {
  timestamp: number;
  price: number;
}

function App() {
  const [priceData, setPriceData] = useState<PriceData[]>([]);
  const [fetching, setFetching] = useState<boolean>(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [lastBackendUpdate, setLastBackendUpdate] = useState<Date | null>(null);

  // Function to fetch the latest data from the backend
  const fetchLatestData = async () => {
    try {
      console.log('[frontend] fetchLatestData called');
      const rawData: string[] = await onchain_oracle_backend.get_latest_data();
      console.log('[frontend] rawData:', rawData);

      // Parse each item in the rawData array into JSON
      const parsedDataArray: number[][][] = rawData.map((item) => JSON.parse(item));
      console.log('[frontend] parsedDataArray:', parsedDataArray);

      const flatData: number[][] = parsedDataArray.flat();
      console.log('[frontend] flatData:', flatData);

      // Extract timestamp and closing price (index 0: timestamp, index 4: close price)
      const formattedData: PriceData[] = flatData.map(([timestamp, , , , closePrice]) => ({
        timestamp: Number(timestamp),
        price: Number(closePrice),
      }));
      console.log('[frontend] formattedData:', formattedData);

      // Update state with the formatted data
      setPriceData(formattedData);

      // Update the last updated time
      setLastUpdated(new Date());

      // Get the latest timestamp from the data
      const latestTimestamp = formattedData[0]?.timestamp;
      if (latestTimestamp) {
        setLastBackendUpdate(new Date(latestTimestamp * 1000));
      }
    } catch (error) {
      console.error("Error fetching latest data:", error);
    }
  };

  // useEffect to initialize setup and start fetching data
  useEffect(() => {
    const initialize = async () => {
      setFetching(true);
      try {
        // Call the setup function on the backend
        await onchain_oracle_backend.setup();

        // Fetch the latest data immediately
        await fetchLatestData();

        // Set up interval to fetch data every 60 seconds
        const intervalId = setInterval(fetchLatestData, 60000);

        // Clean up the interval when the component unmounts
        return () => clearInterval(intervalId);
      } catch (error) {
        console.error("Error during initialization:", error);
      } finally {
        setFetching(false);
      }
    };

    initialize();
  }, []);

  return (
    <main>
      <header>
        <h1>BTC-USD Price Oracle</h1>
      </header>
      <section>
        {fetching && <p>Loading data...</p>}
        {lastUpdated && <p>Frontend last updated: {lastUpdated.toLocaleString()}</p>}
        {lastBackendUpdate && (
          <p>Backend data timestamp: {lastBackendUpdate.toLocaleString()}</p>
        )}
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
                <td>{new Date(timestamp * 1000).toLocaleString()}</td>
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
