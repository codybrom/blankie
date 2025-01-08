// Handle both download and logo links
document.querySelectorAll('a[href*="section=download"]').forEach((anchor) => {
  anchor.addEventListener("click", function (this: HTMLAnchorElement, e) {
    const href = this.getAttribute("href");
    const isIndexPage =
      window.location.pathname === "/" ||
      window.location.pathname.endsWith("index.html");

    // Always prevent default if we're already on index page
    if (isIndexPage) {
      e.preventDefault();
      const target = document.querySelector("#download");

      if (target) {
        const headerHeight = 80;
        const additionalOffset = 200;
        const totalOffset = headerHeight + additionalOffset;

        const elementPosition = target.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.scrollY - totalOffset;

        window.scrollTo({
          top: offsetPosition,
          behavior: "smooth",
        });

        // Update URL without reload
        history.pushState(null, "", href);
      }
      return;
    }
  });
});

// Handle logo click
const logoLink = document.getElementById("logo-link");
if (logoLink) {
  logoLink.addEventListener("click", function (e) {
    const isIndexPage =
      window.location.pathname === "/" ||
      window.location.pathname.endsWith("index.html");
    if (isIndexPage) {
      e.preventDefault();
      window.scrollTo({
        top: 0,
        behavior: "smooth",
      });
      history.pushState(null, "", "/"); // Fixed null parameter
    }
    // If not on index page, let the normal navigation happen
  });
}

// Handle initial load with query param
window.addEventListener("load", function () {
  const params = new URLSearchParams(window.location.search);
  const section = params.get("section");
  if (section === "download") {
    const target = document.querySelector("#download");
    if (target) {
      const headerHeight = 80;
      const additionalOffset = 200;
      const totalOffset = headerHeight + additionalOffset;
      requestAnimationFrame(() => {
        const elementPosition = target.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.scrollY - totalOffset;
        window.scrollTo({
          top: offsetPosition,
          behavior: "smooth",
        });
      });
    }
  }
});

// Mobile menu functionality
const mobileMenuButton = document.getElementById("mobile-menu-button");
const mobileMenu = document.getElementById("mobile-menu");

if (mobileMenuButton && mobileMenu) {
  mobileMenuButton.addEventListener("click", () => {
    // Toggle menu visibility
    if (mobileMenu.classList.contains("hidden")) {
      mobileMenu.classList.remove("hidden");
      mobileMenu.classList.add("block");
    } else {
      mobileMenu.classList.add("hidden");
      mobileMenu.classList.remove("block");
    }
  });
} // Close mobile menu when clicking outside
document.addEventListener("click", (e: MouseEvent) => {
  const target = e.target as Node;
  if (
    mobileMenu &&
    !mobileMenu.contains(target) &&
    mobileMenuButton &&
    !mobileMenuButton.contains(target)
  ) {
    mobileMenu.classList.add("hidden");
    mobileMenu.classList.remove("block");
  }
});

// Close mobile menu when window is resized to desktop size
window.addEventListener("resize", () => {
  if (window.innerWidth >= 768 && mobileMenu) {
    // 768px is the md breakpoint in Tailwind
    mobileMenu.classList.add("hidden");
    mobileMenu.classList.remove("block");
  }
});

// Close mobile menu when clicking a link
if (mobileMenu) {
  mobileMenu.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      mobileMenu.classList.add("hidden");
      mobileMenu.classList.remove("block");
    });
  });
}
