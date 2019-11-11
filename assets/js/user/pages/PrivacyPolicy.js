import React, { useEffect } from "react";
import { Helmet } from "react-helmet-async";
import { useDispatch } from "react-redux";
import useSWR from "swr";
import fetch from "unfetch";
import Loading from "../components/Loading";
import { unfixedNav, settingNavIs } from "../actions";

const title = "POLICR · 隐私政策";
const fetcher = url => fetch(url).then(r => r.json());

export default _props => {
  const dispatch = useDispatch();

  const { data, error } = useSWR("/api/privacy", fetcher);

  useEffect(() => {
    dispatch(settingNavIs("info"));
    dispatch(unfixedNav());
  }, []);

  useEffect(() => {
    window.location.hash = window.decodeURIComponent(window.location.hash);
    const scrollToAnchor = () => {
      const hashParts = window.location.hash.split("#");
      if (hashParts.length >= 2) {
        const hash = hashParts[1];
        const $anchor = document.querySelector(`a.anchor[name="${hash}"]`);
        if ($anchor) {
          $anchor.scrollIntoView();
        }
      }
    };
    scrollToAnchor();
    window.onhashchange = scrollToAnchor;
  }, [data]);

  if (error) return <div>载入数据失败，请刷新。</div>;
  if (!data) return <Loading />;

  return (
    <>
      <Helmet>
        <title>{title}</title>
      </Helmet>

      <section className="hero is-info">
        <div className="hero-body">
          <div className="container">
            <h1 className="title is-spaced">{data.title}</h1>
            <h2 className="subtitle">{data.subtitle}</h2>
          </div>
        </div>
      </section>
      <section id="QAPage" className="section">
        <div className="container">
          <div className="columns">
            <div className="column is-3">
              <div className="pr-sidebar">
                <aside className="menu">
                  <p className="menu-label">{data.title}</p>
                  <ul className="menu-list">
                    {data.sections.map(qa => (
                      <li key={qa.anchor}>
                        <a href={`#${qa.anchor}`}>{qa.title}</a>
                      </li>
                    ))}
                  </ul>
                </aside>
              </div>
            </div>
            <div className="column is9">
              {data.sections.map(qa => (
                <div key={qa.anchor} className="section">
                  <h5 className="subtitle is-3">
                    <a name={qa.anchor} className="anchor"></a>
                    {qa.title}
                  </h5>
                  <hr />
                  <div
                    className="content"
                    dangerouslySetInnerHTML={{ __html: qa.content }}
                  />
                </div>
              ))}
              <div>
                <article className="message is-success">
                  <div className="message-body">
                    本项目当前版本<code>{VERSION}</code>
                    没有持久化储存任何用户普通消息，请安心。
                  </div>
                </article>
                <article className="message is-danger">
                  <div className="message-body">
                    以上内容由源代码保证，接受任何组织或个人的监督。
                  </div>
                </article>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
