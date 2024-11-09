import { useState, useEffect } from "react";
import { onchain_oracle_backend } from "declarations/onchain-oracle-backend";

function App() {
  const [priceData, setPriceData] = useState([]);
  const [fetching, setFetching] = useState(false);

  // Function to fetch the latest data from the backend
  const fetchLatestData = async () => {
    try {
      const rawData = await onchain_oracle_backend.get_latest_data();
      console.log('fetch latest data')
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
  
        // Set up interval to fetch data every minute
        const intervalId = setInterval(fetchLatestData, 60000); // 60000 milliseconds = 1 minute
  
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
        {fetching ? <p>Loading data...</p> : null}
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
