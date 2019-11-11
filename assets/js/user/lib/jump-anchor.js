export default () => {
  window.location.hash = window.decodeURIComponent(window.location.hash);
  const scrollToAnchor = () => {
    const hashParts = window.location.hash.split("#");
    if (hashParts.length >= 2) {
      const hash = hashParts[1];
      const $anchor = document.querySelector(`a.anchor[name="${hash}"]`);
      if ($anchor) {
        $anchor.scrollIntoView({ behavior: "smooth" });
      }
    }
  };
  scrollToAnchor();
  window.onhashchange = scrollToAnchor;
};
