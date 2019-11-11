import React, { useEffect } from "react";
import { Helmet } from "react-helmet-async";
import { useDispatch } from "react-redux";
import ScrollToTop from "../components/ScrollToTop";
import { clearNavIs, fixedNav } from "../actions";

const title = "POLICR · 首页";

const descStyle = {
  backgroundColor: "#ed6129"
};

export default _props => {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fixedNav());
    dispatch(clearNavIs());
  }, []);

  return (
    <>
      <Helmet>
        <title>{title}</title>
      </Helmet>

      <ScrollToTop />

      <section id="IndexPage" className="section hero is-fullheight is-medium">
        <div className="hero-body">
          <div className="container">
            <div className="columns has-text-centered is-centered">
              <div className="column is-12">
                <p className="title is-size-1-desktop is-size-3-mobile is-spaced">
                  <span className="has-text-black-bis has-text-weight-bold">
                    POLICR
                  </span>
                  <span className="has-text-danger has-text-weight-bold">
                    {" "}
                    :{" "}
                  </span>
                  <span className="has-text-grey-dark has-text-weight-light">
                    专注于审核群成员的机器人
                  </span>
                </p>
                <p className="subtitle is-size-3-desktop is-size-5-mobile has-text-grey">
                  提供 Telegram 平台上的<strong>免费</strong>
                  审核服务和应用程序，它拥有强大的定制性，并完全开放
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
      <section className="section" style={descStyle}>
        <div className="columns is-multiline">
          <div className="column is-6 is-3-desktop">
            <div className="card">
              <header className="card-header">
                <p className="card-header-title">加群验证</p>
              </header>
              <div className="card-content">
                <p>
                  提供多种截然不同的验证方式。不仅有常见的固定问答、算术题，还可以下棋、识别或旋转图片。
                </p>
                <p>
                  您甚至能定制一套属于群组自己的问题，设定容错机率。就像考试一样。
                </p>
              </div>
            </div>
          </div>
          <div className="column is-6 is-3-desktop">
            <div className="card">
              <header className="card-header">
                <p className="card-header-title">内容/广告屏蔽</p>
              </header>
              <div className="card-content">
                <p>
                  使用特殊的屏蔽规则灵活配置不想看到的内容，交由自主规则引擎高效率执行。订阅全局规则，封杀流行广告并自动上报。
                </p>
                <p>
                  除此之外，还可以对消息长度、行数进行限制，以及不允许上传的文件格式。
                </p>
              </div>
            </div>
          </div>
          <div className="column is-6 is-3-desktop">
            <div className="card">
              <header className="card-header">
                <p className="card-header-title">黑名单系统</p>
              </header>
              <div className="card-content">
                <p>
                  拦截问题用户的加入，无需验证即可避免骚扰。通过举报进入投票流程，投票结果决定黑名单于否。黑名单是全网共享、公开透明、机制公平的。
                </p>
                <p>
                  黑名单系统还包括有申诉功能，它是自助使用、自动化、无法被程序模拟的。
                </p>
              </div>
            </div>
          </div>
          <div className="column is-6 is-3-desktop">
            <div className="card">
              <header className="card-header">
                <p className="card-header-title">周边功能</p>
              </header>
              <div className="card-content">
                <p>在专注之外，也提供了一些周边功能：</p>
                <div className="content">
                  <ul>
                    <li>欢迎消息功能</li>
                    <li>服务消息删除</li>
                    <li>调查用户来源</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
