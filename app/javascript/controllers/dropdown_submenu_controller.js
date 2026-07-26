import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

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
}
