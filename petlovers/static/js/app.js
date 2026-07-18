document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("form[data-confirm-delete]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      const label = form.dataset.confirmDelete || "este registro";
      if (!window.confirm(`¿Eliminar ${label}? Esta acción no se puede deshacer.`)) {
        event.preventDefault();
      }
    });
  });

  const search = document.querySelector("[data-table-search]");
  const table = document.querySelector("[data-filterable-table]");
  const empty = document.querySelector(".filtered-empty");
  if (search && table) {
    const rows = Array.from(table.querySelectorAll("tbody tr"));
    search.addEventListener("input", () => {
      const query = search.value.trim().toLocaleLowerCase("es");
      let visible = 0;
      rows.forEach((row) => {
        const match = row.textContent.toLocaleLowerCase("es").includes(query);
        row.hidden = !match;
        if (match) visible += 1;
      });
      if (empty) empty.hidden = visible !== 0;
    });
  }
});
