import { useState } from "react";
import { ImportPage } from "./pages/ImportPage";
import { DashboardPage } from "./pages/DashboardPage";

export default function App() {
  const [ready, setReady] = useState(false);
  return (
    <div className="app">
      <header><h1>Game Presenter Tracker (Local)</h1></header>
      {!ready ? <ImportPage onReady={() => setReady(true)} /> : <DashboardPage />}
    </div>
  );
}
