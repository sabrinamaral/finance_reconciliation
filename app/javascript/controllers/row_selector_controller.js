import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['sumDisplay', 'countDisplay', 'panel'];
  static values = { sum: Number };

  selectedRows = new Map(); // id => { model, row }

  // Toggles row selection for summing — does not persist to DB
  toggle(event) {
    const row = event.currentTarget;
    const id = row.dataset.recordId;
    const model = row.dataset.model;
    const amount = parseFloat(row.dataset.amount) || 0;

    if (this.selectedRows.has(id)) {
      this.selectedRows.delete(id);
      this.sumValue -= amount;
      row.classList.remove('selected-for-sum');
    } else {
      this.selectedRows.set(id, { model, row });
      this.sumValue += amount;
      row.classList.add('selected-for-sum');
    }

    this.updateDisplay();
  }

  // Marks all selected rows as checked (reconciled) and persists to DB
  async markChecked(event) {
    event.preventDefault();

    if (this.selectedRows.size === 0) return;

    const idsByModel = {};
    this.selectedRows.forEach(({ model }, id) => {
      idsByModel[model] ||= [];
      idsByModel[model].push(id);
    });

    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute('content');

    const response = await fetch('/reconciliations/bulk_check', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({ ids_by_model: idsByModel }),
    });

    if (response.ok) {
      // Update UI for all selected rows without a full page reload
      this.selectedRows.forEach(({ row }) => {
        row.classList.add('checked');
        const checkbox = row.querySelector("input[type='checkbox']");
        if (checkbox) checkbox.checked = true;
      });

      this.clearSelection();
    }
  }

  // Clears selection and hides the panel
  reset() {
    this.clearSelection();
  }

  // Closes panel and clears selection
  close() {
    this.clearSelection();
    this.panelTarget.style.display = 'none';
  }

  // Updates the sum and count display
  updateDisplay() {
    const formatted = this.sumValue.toLocaleString('pt-BR', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
    this.sumDisplayTarget.textContent = formatted;
    this.countDisplayTarget.textContent = this.selectedRows.size;
    this.panelTarget.style.display = 'block';
  }

  // Removes visual selection from all rows and resets sum
  clearSelection() {
    this.selectedRows.forEach(({ row }) => {
      row.classList.remove('selected-for-sum');
    });
    this.selectedRows.clear();
    this.sumValue = 0;
    this.sumDisplayTarget.textContent = '0,00';
    this.countDisplayTarget.textContent = '0';
  }
}
