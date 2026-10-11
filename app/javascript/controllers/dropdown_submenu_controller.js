import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  connect() {
    // Close the submenu whenever the parent Bootstrap dropdown closes
    this.dropdown = this.element.closest(".dropdown");
    this.close = this.close.bind(this);
    this.dropdown?.addEventListener("hidden.bs.dropdown", this.close);
  }

  disconnect() {
    this.dropdown?.removeEventListener("hidden.bs.dropdown", this.close);
  }

  // Toggles the submenu open/closed without closing the parent dropdown
  toggle(event) {
    event.preventDefault();
    event.stopPropagation();

    const isOpen = this.menuTarget.classList.contains("show");

    // Close any other open submenus first
    document.querySelectorAll(".submenu.show").forEach((menu) => {
      if (menu !== this.menuTarget) menu.classList.remove("show");
    });

    this.menuTarget.classList.toggle("show", !isOpen);
  }

  close() {
    this.menuTarget.classList.remove("show");
  }
}
