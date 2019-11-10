import React, { useEffect } from "react";
import { useSelector } from "react-redux";
import { Link } from "react-router-dom";

const borderNoneStyle = {
  border: "none"
};

function burgerToggle(el, always_close = false) {
  // Get the target from the "data-target" attribute
  const target = el.dataset.target;
  const $target = document.getElementById(target);

  if (!always_close) {
    // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
    el.classList.toggle("is-active");
    $target.classList.toggle("is-active");
  } else {
    el.classList.remove("is-active");
    $target.classList.remove("is-active");
  }
}

const initialNavClass = ["navbar", "is-fixed-top", "pr-nav"];
const allIs = ["is-info", "is-success"];

function Header() {
  const header = useSelector(state => state.header);
  const { is } = header;

  let navClass = [...initialNavClass];
  if (is) {
    navClass.push(is);
  } else {
    navClass = navClass.filter(c => !allIs.includes(c));
  }

  // 初始化导航栏事件
  useEffect(() => {
    const $navbarBurgers = document.querySelectorAll(".navbar-burger");
    const $navbarItems = document.querySelectorAll(".navbar-item");

    // Check if there are any navbar burgers
    if ($navbarBurgers.length > 0) {
      // Add a click event on each of them
      $navbarBurgers.forEach(el => {
        el.addEventListener("click", () => {
          burgerToggle(el);
        });
      });
    }

    if ($navbarItems.length > 0) {
      $navbarItems.forEach(el => {
        el.addEventListener("click", () => {
          $navbarBurgers.forEach(el => {
            burgerToggle(el, true);
          });
        });
      });
    }
  }, []);

  return (
    <header>
      <nav
        className={navClass.join(" ")}
        role="navigation"
        aria-label="main navigation"
      >
        <div className="container">
          <div className="navbar-brand">
            <Link className="navbar-item" to="/beta">
              首页
            </Link>
            <Link to="/beta/getting-started" className="navbar-item">
              入门
            </Link>
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
                  <Link className="navbar-item" to="/beta/advanced">
                    高级教程
                  </Link>
                  <Link className="navbar-item" to="/beta/qa">
                    常见问题
                  </Link>
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
