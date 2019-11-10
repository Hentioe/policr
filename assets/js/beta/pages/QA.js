import React, { useEffect } from "react";
import { Helmet } from "react-helmet-async";
import { useDispatch } from "react-redux";
import useSWR from "swr";
import fetch from "unfetch";
import { settingNavIs } from "../actions";

const title = "POLICR · 常见问题";
const fetcher = url => fetch(url).then(r => r.json());

export default () => {
  const dispatch = useDispatch();

  const { data, error } = useSWR("/api/qa", fetcher);

  useEffect(() => {
    dispatch(settingNavIs("success"));
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
  if (!data) return <div>加载中……</div>;

  return (
    <>
      <Helmet>
        <title>{title}</title>
      </Helmet>

      <section className="hero is-success">
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
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
