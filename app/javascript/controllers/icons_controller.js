import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["edit", "delete", "cancelEdit"];

  edit(event) {
    event.preventDefault();
    const recordId = event.target.dataset.recordId;
    const editUrl = `/cash_flows/${recordId}/edit`;

    document.getElementById(`record-${recordId}`).style.display = "none";
    document.getElementById(`edit-form-${recordId}`).style.display =
      "table-row";
  }

  cancelEdit(event) {
    event.preventDefault();
    const recordId = event.currentTarget.dataset.recordId;

    document.getElementById(`record-${recordId}`).style.display = "table-row";
    document.getElementById(`edit-form-${recordId}`).style.display = "none";
  }
  delete(event) {
    event.preventDefault();
    const recordId = event.target.dataset.recordId;

    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content");

    fetch(`/cash_flows/${recordId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json",
      },
    })
      .then(async (response) => {
        const data = await response.json();
        if (response.ok) {
          document.getElementById(`record-${recordId}`).remove();
          this.showFlashMessage("notice", data.message);
        } else {
          this.showFlashMessage("alert", data.error);
        }
      })
      .catch((error) => {
        console.error("Error:", error);
        this.showFlashMessage(
          "alert",
          "Something went wrong while trying deleting this record."
        );
      });
  }

  showFlashMessage(type, message) {
    // Clear existing flash messages
    const flashMessagesContainer = document.querySelector(".flash-container");

    if (flashMessagesContainer) {
      flashMessagesContainer.innerHTML = "";
    } else {
      console.error("Flash messages container not found");
      return;
    }

    // Create a new flash message
    const flashContainer = document.createElement("div");
    flashContainer.className = `alert alert-${
      type === "notice" ? "info" : "danger"
    } mt-4`;
    flashContainer.setAttribute("role", "alert");
    flashContainer.innerText = message;

    // Append the new flash message
    flashMessagesContainer.appendChild(flashContainer);

    // Remove the flash message after 3 seconds
    setTimeout(() => {
      flashContainer.remove();
    }, 3000);
  }
}
