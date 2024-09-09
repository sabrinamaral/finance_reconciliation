import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];

  submit(event) {
    event.preventDefault();
    const formData = new FormData(this.formTarget);
    console.log(this.formTarget.method);

    fetch(this.formTarget.action, {
      method: this.formTarget.method,
      body: formData,
      headers: {
        "X-CSRF-Token": document
          .querySelector('meta[name="csrf-token"]')
          .getAttribute("content"),
      },
    }).then((response) => {
      if (response.ok) {
        console.log("Form submitted successfully");
        this.formTarget.reset(); // reset the form
        window.location.href = "/cash_flows"; // Redirect to the cash flows path
      }
    });
  }
}
