import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['checkbox'];

  connect() {}

  // Handles checkbox click — toggles checked state and persists to DB
  toggleChecked(event) {
    event.stopPropagation();

    const checkbox = event.currentTarget;
    const row = checkbox.closest('tr');
    const id = checkbox.dataset.recordId;
    const model = checkbox.dataset.model;

    row.classList.toggle('checked');

    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute('content');

    fetch('this.urlValue', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({ id, model }),
    });
  }
}
