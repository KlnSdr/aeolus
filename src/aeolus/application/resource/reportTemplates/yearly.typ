#set text(lang: "de")
#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  } else if y > 1 {
    (top: 0.7pt + gray)
  },
  align: (x, y) => (
    if x > 0 { center }
    else { left }
  )
)

#set page(
  footer: text(font: "New Computer Modern Mono")[automatisch erzeugt am #datetime.today().display("[day].[month].[year]")]
)

#grid(
  rows: auto,
  columns: (auto, auto),
  align: horizon,
  column-gutter: 1em,
  // image("aeolus.png", height: 50pt),
  [= Jahresbericht {{year}}]
)

_Jahresberichte werden leider aktuell nicht vollständig unterstützt._