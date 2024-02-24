import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [ "row" ]
  connect() {

  }

  changeColor(event) {
    let row = event.currentTarget;
    let cells = row.getElementsByTagName('td');
    for (let i = 0; i < cells.length; i++) {
      cells[i].classList.toggle('highlight');
    }
  }

}
