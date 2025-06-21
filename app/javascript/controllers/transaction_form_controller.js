import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["transaction_form"];

  submit(event) {
    event.preventDefault();
    const formData = new FormData(this.transactionFormTarget);

    fetch(this.transactionFormTarget.action, {
      method: this.transactionFormTarget.method,
      body: formData,
      headers: {
        "X-CSRF-Token": document
          .querySelector('meta[name="csrf-token"]')
          .getAttribute("content"),
      },
    }).then((response) => {
      if (response.ok) {
        console.log("Form submitted successfully");
        this.transactionFormTarget.reset(); // reset the form
        window.location.href = "/cash_flows"; // Redirect to the cash flows path
      }
    });
  }
}
