#import "@preview/lilaq:0.5.0" as lq

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

#let UP = text(fill: red)[$triangle.filled.t$]
#let DOWN = text(fill: green)[$triangle.filled.b$]
#let SAME = text(fill: gray)[$circle.filled$]

#let rawdata = "
{{temperatures}}
"

#let data = csv(bytes(rawdata)).map(p => (
    datetime(
      year: int(p.first().split("-").first()),
      month: int(p.first().split("-").at(1)),
      day: int(p.first().split("-").last()),
    ),
    float(p.last())
  )
)

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

#let UP = text(fill: red)[$triangle.filled.t$]
#let DOWN = text(fill: green)[$triangle.filled.b$]
#let SAME = text(fill: gray)[$circle.filled$]
#let calcTrend(a, b) = {
  if (a < b) {
    return DOWN;
  } else if (a > b) {
    return UP;
  } else {
    return SAME;
  }
}

#grid(
  rows: auto,
  columns: (auto, auto),
  align: horizon,
  column-gutter: 1em,
  // image("aeolus.png", height: 50pt),
  [= Monatsbericht {{month}}.{{year}}]
)

#table(
  columns: (1fr, auto, auto, auto),
  row-gutter: 5pt,
  align: horizon + left,
  table.header(
    [Kategorie],
    [Wert],
    [Durchschnitt],
    [Trend]
  ),
  [Betriebsstunden (Heizung)], [${{operatingHoursHeating}} h$], [${{averageOperatingHoursHeating}} h$], calcTrend({{operatingHoursHeating}}, {{averageOperatingHoursHeating}}),
  [Betriebsstunden (Wasser)], [${{operatingHoursWater}} h$], [${{averageOperatingHoursWater}} h$], calcTrend({{operatingHoursWater}}, {{averageOperatingHoursWater}}),
  [Betriebsstunden 2], [${{operatingHoursTwo}} "kW"/h$], [${{averageOperatingHoursTwo}} "kW"/h$], calcTrend({{operatingHoursTwo}}, {{averageOperatingHoursTwo}}),
  [Hochtarifstrom (1.81)], [${{highTariffPower}} "kW"/h$], [${{averageHighTariffPower}} "kW"/h$], calcTrend({{highTariffPower}}, {{averageHighTariffPower}}),
  [Niedrigtarifstrom (1.82)], [${{lowTariffPower}} "kW"/h$], [${{averageLowTariffPower}} "kW"/h$], calcTrend({{lowTariffPower}}, {{averageLowTariffPower}}),
  [Bestand am Monatsende (Hausstrom)], [${{householdPower}} "kW"/h$], [${{averageHouseholdPower}} "kW"/h$], calcTrend({{householdPower}}, {{averageHouseholdPower}}),
  [Bestand am Monatsende (Wasser)], [${{householdWater}} m^3$], [${{averageHouseholdWater}} m^3$], calcTrend({{householdWater}}, {{averageHouseholdWater}}),
  [Temperaturdurchschnitt], [${{temperatureAverage}} °C$], [${{averageTemperatureAverage}} °C$], calcTrend({{temperatureAverage}}, {{averageTemperatureAverage}}),
  [wärmster Tag], [${{temperatureMax}} °C$], [${{averageTemperatureMax}} °C$], calcTrend({{temperatureMax}}, {{averageTemperatureMax}}),
  [kältester Tag], [${{temperatureMin}} °C$], [${{averageTemperatureMin}} °C$], calcTrend({{temperatureMin}}, {{averageTemperatureMin}}),
)

#lq.diagram(
      width: 100%,
      height: 50%,
      ylim: (-20, 35),
      ylabel: [Temperatur in °C],
      xlabel: [Datum],
      xaxis: (
        format-ticks: lq.tick-format.datetime.with(
          format: "[day].[month]",
        ),
      ),
      lq.rect(0%, 2.97cm, width: 100%, height: 2cm, fill: gray),
      lq.plot(
        data.map(p => p.first()),
        data.map(p => p.last()),
        color: rgb("000"),
        mark: none,
        stroke: 2pt
    ),
    title: [== {{month}}.{{year}}],
  )