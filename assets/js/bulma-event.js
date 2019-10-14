document.addEventListener("DOMContentLoaded", () => {
  // Get all "navbar-burger" elements
  const $navbarBurgers = Array.prototype.slice.call(
    document.querySelectorAll(".navbar-burger"),
    0
  );
  const $navbarItems = Array.prototype.slice.call(
    document.querySelectorAll(".navbar-item"),
    0
  );

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
          burgerToggle(el, (always_close = true));
        });
      });
    });
  }
});

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
