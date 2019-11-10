import React from "react";

const borderNoneStyle = {
  border: "none"
}

function Header() {
  return (
    <header>
      <nav
        className="navbar is-fixed-top pr-nav"
        role="navigation"
        aria-label="main navigation"
      >
        <div className="container">
          <div className="navbar-brand">
            <a className="navbar-item" href="/">
              首页
            </a>
            <a href="/getting-started" className="navbar-item">
              入门
            </a>
            <a
              className="navbar-item"
              target="_blank"
              href="https://policr.bluerain.io/community"
            >
              社区
            </a>
            <a
              role="button"
              className="navbar-burger burger"
              aria-label="menu"
              aria-expanded="false"
              data-target="navbarBasicExample"
            >
              <span aria-hidden="true"></span>
              <span aria-hidden="true"></span>
              <span aria-hidden="true"></span>
            </a>
          </div>

          <div id="navbarBasicExample" className="navbar-menu">
            <div className="navbar-end">
              <div className="navbar-item has-dropdown is-hoverable">
                <a className="navbar-link">文档指南</a>
                <div className="navbar-dropdown is-boxed">
                  <a className="navbar-item" href="/advanced">
                    高级教程
                  </a>
                  <a className="navbar-item" href="/qa">
                    常见问题
                  </a>
                  <a className="navbar-item">私有部署</a>
                  <hr className="navbar-divider" />
                  <a className="navbar-item">版本变化</a>
                </div>
              </div>
              <div className="navbar-item">
                <div className="field is-grouped">
                  <p className="control">
                    <a
                      className="button has-text-white has-background-primary"
                      target="_blank"
                      style={borderNoneStyle}
                      href="https://t.me/policr_bot"
                    >
                      <span className="icon">
                        <i className="fas fa-robot"></i>
                      </span>
                      <span>领取机器人</span>
                    </a>
                  </p>
                  <p className="control">
                    <a
                      className="button has-text-white has-background-black"
                      style={borderNoneStyle}
                      href="https://github.com/Hentioe/policr"
                      target="_blank"
                    >
                      <span className="icon">
                        <i className="fab fa-github-alt"></i>
                      </span>
                      <span>GitHub</span>
                    </a>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </nav>
    </header>
  );
}

export default Header;
