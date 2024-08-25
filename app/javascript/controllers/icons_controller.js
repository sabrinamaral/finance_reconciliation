import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["edit", "delete", "cancelEdit", "saveEdit"];

  // connect() {
  //   console.log("Icon controller connected");
  // }

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
  // delete(event) {
  //   event.preventDefault();
  //   console.log("Delete icon clicked");
  //   // Add your delete logic here
  // }
}
