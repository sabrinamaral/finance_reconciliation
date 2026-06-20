import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['dayButton', 'row'];

  // Filters rows to show only the selected day. "all" shows everything.
  filter(event) {
    const selectedDay = event.currentTarget.dataset.day;

    // Update active state on day buttons
    this.dayButtonTargets.forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.day === selectedDay);
    });

    // Show/hide rows based on their date
    this.rowTargets.forEach((row) => {
      const rowDay = row.dataset.day;
      const shouldShow = selectedDay === 'all' || rowDay === selectedDay;
      row.style.display = shouldShow ? '' : 'none';
    });
  }
}
