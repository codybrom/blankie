class SiteNavigation {
  private mobileButton: HTMLElement | null;
  private mobileMenu: HTMLElement | null;
  private logoLink: HTMLElement | null;
  private mediaQuery: MediaQueryList;
  private readonly HEADER_HEIGHT = 80;
  private readonly ADDITIONAL_OFFSET = 200;

  constructor() {
    this.mobileButton = document.getElementById("mobile-menu-button");
    this.mobileMenu = document.getElementById("mobile-menu");
    this.logoLink = document.getElementById("logo-link");
    this.mediaQuery = window.matchMedia("(min-width: 768px)");

    this.init();
  }

  private init(): void {
    this.setupDownloadLinks();
    this.setupLogoLink();
    this.setupMobileMenu();
    this.handleInitialLoad();
  }

  private isIndexPage(): boolean {
    return (
      window.location.pathname === "/" ||
      window.location.pathname.endsWith("index.html")
    );
  }

  private setupDownloadLinks(): void {
    document
      .querySelectorAll('a[href*="section=download"]')
      .forEach((anchor) => {
        anchor.addEventListener("click", (e: Event) => {
          const link = e.currentTarget as HTMLAnchorElement; // Use currentTarget instead of casting anchor
          const href = link.getAttribute("href");

          if (this.isIndexPage() && href) {
            e.preventDefault();
            this.scrollToDownload();
            history.pushState(null, "", href);
          }
        });
      });
  }

  private setupLogoLink(): void {
    this.logoLink?.addEventListener("click", (e: Event) => {
      // Changed from MouseEvent to Event
      if (this.isIndexPage()) {
        e.preventDefault();
        this.scrollToTop();
        history.pushState(null, "", "/");
      }
    });
  }

  private scrollToElement(element: Element, offset = 0): void {
    requestAnimationFrame(() => {
      const elementPosition = element.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.scrollY - offset;

      window.scrollTo({
        top: offsetPosition,
        behavior: "smooth",
      });
    });
  }

  private scrollToDownload(): void {
    const target = document.querySelector("#download");
    if (target) {
      const totalOffset = this.HEADER_HEIGHT + this.ADDITIONAL_OFFSET;
      this.scrollToElement(target, totalOffset);
    }
  }

  private scrollToTop(): void {
    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  private handleInitialLoad(): void {
    window.addEventListener("load", () => {
      const params = new URLSearchParams(window.location.search);
      if (params.get("section") === "download") {
        this.scrollToDownload();
      }
    });
  }

  private setupMobileMenu(): void {
    if (!this.mobileButton || !this.mobileMenu) return;

    // Toggle menu
    this.mobileButton.addEventListener("click", () => {
      const isExpanded = !this.mobileMenu?.classList.contains("hidden");
      this.setMenuState(!isExpanded);
    });

    // Close on outside click
    document.addEventListener("click", this.handleClickOutside.bind(this));

    // Handle screen resize
    this.mediaQuery.addEventListener("change", this.handleResize.bind(this));

    // Close on link click
    this.mobileMenu.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => this.setMenuState(false));
    });
  }

  private setMenuState(isOpen: boolean): void {
    if (!this.mobileMenu || !this.mobileButton) return;

    this.mobileMenu.classList.toggle("hidden", !isOpen);
    this.mobileMenu.classList.toggle("block", isOpen);
    this.mobileButton.setAttribute("aria-expanded", isOpen.toString());

    if (isOpen) {
      this.mobileMenu.focus();
    }
  }

  private handleClickOutside(event: Event): void {
    const target = event.target as Node;

    if (
      !this.mobileMenu?.contains(target) &&
      !this.mobileButton?.contains(target)
    ) {
      this.setMenuState(false);
    }
  }

  private handleResize(event: MediaQueryListEvent): void {
    if (event.matches) {
      this.setMenuState(false);
    }
  }

  public destroy(): void {
    this.mediaQuery.removeEventListener("change", this.handleResize.bind(this));
    document.removeEventListener("click", this.handleClickOutside.bind(this));
  }
}

// Initialize when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  new SiteNavigation();
});
