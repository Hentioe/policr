// Styles
import "../scss/beta.scss";
// Icons
import "@fortawesome/fontawesome-free/js/all";
// Polyfills
import "mdn-polyfills/CustomEvent";
import "mdn-polyfills/String.prototype.startsWith";
import "mdn-polyfills/NodeList.prototype.forEach";
import "mdn-polyfills/Object.assign";
import "mdn-polyfills/Element.prototype.classList";

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { HelmetProvider } from "react-helmet-async";

// 导入组件和页面
import Header from "./beta/components/Header";
import Footer from "./beta/components/Footer";
import Index from "./beta/pages/Index";

class App extends React.Component {
  render() {
    return (
      <Router>
        <HelmetProvider>
          <Header />
          <main>
            <Switch>
              <Route path="/">
                <Index />
              </Route>
            </Switch>
          </main>
          <Footer />
        </HelmetProvider>
      </Router>
    );
  }
}

ReactDOM.render(<App />, document.getElementById("app"));
