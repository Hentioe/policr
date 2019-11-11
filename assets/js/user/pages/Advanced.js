import React, { useEffect } from "react";
import { Helmet } from "react-helmet-async";
import { useDispatch } from "react-redux";
import useSWR from "swr";
import fetch from "unfetch";
import { useLocation } from "react-router-dom";
import Loading from "../components/Loading";
import { settingNavIs, unfixedNav } from "../actions";
import jumpAnchor from "../lib/jump-anchor";

const title = "POLICR · 高级教程";
const fetcher = url => fetch(url).then(r => r.json());

export default _props => {
  const dispatch = useDispatch();
  const { pathname } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);

  const { data, error } = useSWR("/api/advanced", fetcher);

  useEffect(() => {
    dispatch(settingNavIs("info"));
    dispatch(unfixedNav());
  }, []);

  useEffect(() => {
    jumpAnchor();
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
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
