<p align="center">
  <img src="src/aeolus/application/resource/static/favicon.png" width="80" alt="Aeolus logo">
</p>

<h1 align="center">Aeolus</h1>

<p align="center">
  A tool for tracking daily temperatures and heat pump data over time.
</p>

## About

Aeolus records daily average temperatures and monthly
heat pump data (operating hours, power consumption, water usage, and more)
and turns it into charts, comparisons, and monthly/yearly PDF reports.

## Features

- **Daily readings** - daily average temperature, recorded manually or via API
- **Monthly values** - heat pump metrics per month (operating hours, power
  draw, tariffs, water usage, ...)
- **Charts & visualizations** - temperature and usage trends over months
  and years
- **Year comparison** - two years compared side by side
- **Data quality checks** - automatic detection of gaps/anomalies in
  readings, with interpolation for small gaps
- **Reports** - automatically generated monthly/yearly PDF reports
  (temperature curve, trends, averages, operating hours, tariffs, ...)
- **CSV export** - readings for a given month or year
- **REST API** - documented under `/apidocs/index.html` in the running application