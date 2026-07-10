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
  footer: text(font: "New Computer Modern")[automatisch erzeugt am #datetime.today().display("[day].[month].[year]")]
)

#let features = ({{features}})

#let renderOptional(feature, content) = [
  #if (features.contains(feature)) {
    content
  }
]

#let UP = text(fill: red)[$triangle.filled.t$]
#let DOWN = text(fill: green)[$triangle.filled.b$]
#let SAME = text(fill: gray)[$circle.filled$]

#let rawdata = "
{{temperatures}}
"

#let data = ()
#if (features.contains("TEMPERATURE_CURVE")) {
    data = csv(bytes(rawdata)).map(p => (
        datetime(
          year: int(p.first().split("-").first()),
          month: int(p.first().split("-").at(1)),
          day: int(p.first().split("-").last()),
        ),
        float(p.last())
      )
    )
}

#let operatingHoursHeatingCurveRaw = "
{{operatingHoursHeatingCurve}}
"
#let operatingHoursWaterCurveRaw = "
{{operatingHoursWaterCurve}}
"
#let operatingHoursTwoCurveRaw = "
{{operatingHoursTwoCurve}}
"
#let highTariffPowerCurveRaw = "
{{highTariffPowerCurve}}
"
#let lowTariffPowerCurveRaw = "
{{lowTariffPowerCurve}}
"
#let householdPowerCurveRaw = "
{{householdPowerCurve}}
"
#let householdWaterCurveRaw = "
{{householdWaterCurve}}
"

#let parseMonthlyCurve(raw) = {
  if (raw.trim() == "") {
    return ()
  }
  return csv(bytes(raw)).map(p => (int(p.first()), float(p.last())))
}

#let monthlyValuesPlots = ()

#if (features.contains("OPERATING_HOURS_HEATING_CURVE")) {
  let curve = parseMonthlyCurve(operatingHoursHeatingCurveRaw)
  monthlyValuesPlots += (lq.bar(
    curve.map(p => p.first()),
    curve.map(p => p.last()),
    width: 0.4,
    align: left,
    fill: rgb("d95f02"),
    label: [Betriebsstunden Heizung],
  ),)
}

#if (features.contains("OPERATING_HOURS_WATER_CURVE")) {
  let curve = parseMonthlyCurve(operatingHoursWaterCurveRaw)
  monthlyValuesPlots += (lq.bar(
    curve.map(p => p.first()),
    curve.map(p => p.last()),
    width: 0.4,
    align: right,
    fill: rgb("1f78b4"),
    label: [Betriebsstunden Wasser],
  ),)
}

#if (features.contains("OPERATING_HOURS_TWO_CURVE")) {
  let curve = parseMonthlyCurve(operatingHoursTwoCurveRaw)
  monthlyValuesPlots += (lq.plot(
    curve.map(p => p.first()),
    curve.map(p => p.last()),
    color: rgb("33a02c"),
    mark: "o",
    stroke: 2pt,
    label: [Betriebsstunden 2],
  ),)
}

#if (features.contains("HIGH_TARIFF_POWER_CURVE")) {
  let curve = parseMonthlyCurve(highTariffPowerCurveRaw)
  monthlyValuesPlots += (lq.plot(
    curve.map(p => p.first()),
    curve.map(p => p.last()),
    color: rgb("e31a1c"),
    mark: "o",
    stroke: 2pt,
    label: [Hochtarifstrom],
  ),)
}

#if (features.contains("LOW_TARIFF_POWER_CURVE")) {
  let curve = parseMonthlyCurve(lowTariffPowerCurveRaw)
  monthlyValuesPlots += (lq.plot(
    curve.map(p => p.first()),
    curve.map(p => p.last()),
    color: rgb("6a3d9a"),
    mark: "o",
    stroke: 2pt,
    label: [Niedrigtarifstrom],
  ),)
}

#if (features.contains("HOUSEHOLD_POWER_CURVE")) {
  let curve = parseMonthlyCurve(householdPowerCurveRaw)
  monthlyValuesPlots += (lq.plot(
    curve.map(p => p.first()),
    curve.map(p => p.last()),
    color: rgb("b15928"),
    mark: "o",
    stroke: 2pt,
    label: [Hausstrom],
  ),)
}

#if (features.contains("HOUSEHOLD_WATER_CURVE")) {
  let curve = parseMonthlyCurve(householdWaterCurveRaw)
  monthlyValuesPlots += (lq.plot(
    curve.map(p => p.first()),
    curve.map(p => p.last()),
    color: rgb("737373"),
    mark: "o",
    stroke: 2pt,
    label: [Wasserverbrauch],
  ),)
}

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
  [= Jahresbericht {{year}}]
)

#table(
  columns: (1fr, auto, auto, auto),
  row-gutter: 5pt,
  align: horizon + left,
  table.header(
    [Kategorie],
    [Wert],
    renderOptional("AVERAGES", [Durchschnitt]),
    renderOptional("TREND", [Trend])
  ),
  [Betriebsstunden (Heizung)], [${{operatingHoursHeating}} h$], renderOptional("AVERAGES", [${{averageOperatingHoursHeating}} h$]), renderOptional("TREND", calcTrend({{operatingHoursHeating}}, {{averageOperatingHoursHeating}})),
  [Betriebsstunden (Wasser)], [${{operatingHoursWater}} h$], renderOptional("AVERAGES", [${{averageOperatingHoursWater}} h$]), renderOptional("TREND", calcTrend({{operatingHoursWater}}, {{averageOperatingHoursWater}})),
  [Betriebsstunden 2], [${{operatingHoursTwo}} "kW"/h$], renderOptional("AVERAGES", [${{averageOperatingHoursTwo}} "kW"/h$]), renderOptional("TREND", calcTrend({{operatingHoursTwo}}, {{averageOperatingHoursTwo}})),
  [Hochtarifstrom (1.81)], [${{highTariffPower}} "kW"/h$], renderOptional("AVERAGES", [${{averageHighTariffPower}} "kW"/h$]), renderOptional("TREND", calcTrend({{highTariffPower}}, {{averageHighTariffPower}})),
  [Niedrigtarifstrom (1.82)], [${{lowTariffPower}} "kW"/h$], renderOptional("AVERAGES", [${{averageLowTariffPower}} "kW"/h$]), renderOptional("TREND", calcTrend({{lowTariffPower}}, {{averageLowTariffPower}})),
  [Bestand am Jahresende (Hausstrom)], [${{householdPower}} "kW"/h$], renderOptional("AVERAGES", [${{averageHouseholdPower}} "kW"/h$]), renderOptional("TREND", calcTrend({{householdPower}}, {{averageHouseholdPower}})),
  [Bestand am Jahresende (Wasser)], [${{householdWater}} m^3$], renderOptional("AVERAGES", [${{averageHouseholdWater}} m^3$]), renderOptional("TREND", calcTrend({{householdWater}}, {{averageHouseholdWater}})),
  [Temperaturdurchschnitt], [${{temperatureAverage}} °C$], renderOptional("AVERAGES", [${{averageTemperatureAverage}} °C$]), renderOptional("TREND", calcTrend({{temperatureAverage}}, {{averageTemperatureAverage}})),
  [wärmster Tag], [${{temperatureMax}} °C$], renderOptional("AVERAGES", [${{averageTemperatureMax}} °C$]), renderOptional("TREND", calcTrend({{temperatureMax}}, {{averageTemperatureMax}})),
  [kältester Tag], [${{temperatureMin}} °C$], renderOptional("AVERAGES", [${{averageTemperatureMin}} °C$]), renderOptional("TREND", calcTrend({{temperatureMin}}, {{averageTemperatureMin}})),
)

#if (features.contains("TEMPERATURE_CURVE")) {
    lq.diagram(
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
        title: [== {{year}}],
      )
}

#if (monthlyValuesPlots.len() > 0) {
    lq.diagram(
          width: 100%,
          height: 50%,
          xlabel: [Monat],
          ylabel: [Wert],
          legend: (position: top + left),
          ..monthlyValuesPlots,
          title: [== Jahreswerte im Monatsverlauf],
      )
}
