class SiteNavigation {
  private mobileButton: HTMLElement | null;
  private mobileMenu: HTMLElement | null;
  private mediumButton: HTMLElement | null;
  private mediumMenu: HTMLElement | null;
  private logoLink: HTMLElement | null;
  private mobileMediaQuery: MediaQueryList;
  private mediumMediaQuery: MediaQueryList;
  private readonly HEADER_HEIGHT = 80;
  private readonly ADDITIONAL_OFFSET = 200;

  constructor() {
    this.mobileButton = document.getElementById("mobile-menu-button");
    this.mobileMenu = document.getElementById("mobile-menu");
    this.mediumButton = document.getElementById("medium-menu-button");
    this.mediumMenu = document.getElementById("medium-menu");
    this.logoLink = document.getElementById("logo-link");
    this.mobileMediaQuery = window.matchMedia("(min-width: 768px)");
    this.mediumMediaQuery = window.matchMedia("(min-width: 1024px)");
    this.handleClickOutside = this.handleClickOutside.bind(this);
    this.handleResize = this.handleResize.bind(this);

    this.init();
  }

  private init(): void {
    this.setupDownloadLinks();
    this.setupLogoLink();
    this.setupMobileMenu();
    this.setupMediumMenu();
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
      this.setMobileMenuState(!isExpanded);
    });

    // Close on outside click
    document.addEventListener("click", this.handleClickOutside);

    // Handle screen resize
    this.mobileMediaQuery.addEventListener("change", this.handleResize);

    // Close on link click
    this.mobileMenu.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => this.setMobileMenuState(false));
    });
  }

  private setupMediumMenu(): void {
    if (!this.mediumButton || !this.mediumMenu) return;

    // Toggle menu
    this.mediumButton.addEventListener("click", () => {
      const isExpanded = !this.mediumMenu?.classList.contains("hidden");
      this.setMediumMenuState(!isExpanded);
    });

    // Handle screen resize
    this.mediumMediaQuery.addEventListener("change", this.handleResize);

    // Close on link click
    this.mediumMenu.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => this.setMediumMenuState(false));
    });
  }

  private setMobileMenuState(isOpen: boolean): void {
    if (!this.mobileMenu || !this.mobileButton) return;

    this.mobileMenu.classList.toggle("hidden", !isOpen);
    this.mobileMenu.classList.toggle("block", isOpen);
    this.mobileButton.setAttribute("aria-expanded", isOpen.toString());

    if (isOpen) {
      this.mobileMenu.focus();
    }
  }

  private setMediumMenuState(isOpen: boolean): void {
    if (!this.mediumMenu || !this.mediumButton) return;

    this.mediumMenu.classList.toggle("hidden", !isOpen);
    this.mediumMenu.classList.toggle("block", isOpen);
    this.mediumButton.setAttribute("aria-expanded", isOpen.toString());

    if (isOpen) {
      this.mediumMenu.focus();
    }
  }

  private handleClickOutside(event: Event): void {
    const target = event.target as Node;

    if (
      !this.mobileMenu?.contains(target) &&
      !this.mobileButton?.contains(target)
    ) {
      this.setMobileMenuState(false);
    }

    if (
      !this.mediumMenu?.contains(target) &&
      !this.mediumButton?.contains(target)
    ) {
      this.setMediumMenuState(false);
    }
  }

  private handleResize(event: MediaQueryListEvent): void {
    if (event.matches) {
      this.setMobileMenuState(false);
      this.setMediumMenuState(false);
    }
  }

  public destroy(): void {
    this.mobileMediaQuery.removeEventListener("change", this.handleResize);
    this.mediumMediaQuery.removeEventListener("change", this.handleResize);
    document.removeEventListener("click", this.handleClickOutside);
  }
}

// Initialize when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  new SiteNavigation();
});
