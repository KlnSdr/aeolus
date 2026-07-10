package aeolus.reports.rendering;

import aeolus.application.Main;
import aeolus.readings.MonthlyValues;
import aeolus.readings.Reading;
import aeolus.readings.service.MonthlyValuesService;
import aeolus.readings.service.ReadingService;
import aeolus.reports.Report;
import aeolus.reports.ReportFeatures;
import aeolus.reports.ReportType;
import aeolus.reports.rendering.dto.TableValuesDTO;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import common.logger.Logger;
import common.util.TemplateEngine;
import dobby.files.StaticFile;
import dobby.util.Tupel;
import dobby.util.json.NewJson;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Comparator;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.UUID;
import java.util.function.ToIntFunction;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static aeolus.util.IsoDate.toIsoDateString;
import static hades.common.Util.prependZero;

@RegisterFor(ReportPdfRenderer.class)
public class ReportPdfRenderer {
    private static final Logger LOGGER = new Logger(ReportPdfRenderer.class);
    private final ReadingService readingService;
    private final MonthlyValuesService monthlyValuesService;
    private final TemplateEngine templateEngine;
    private final PdfRenderer pdfRenderer;

    @Inject
    public ReportPdfRenderer(ReadingService readingService, MonthlyValuesService monthlyValuesService,  TemplateEngine templateEngine,  PdfRenderer pdfRenderer) {
        this.readingService = readingService;
        this.monthlyValuesService = monthlyValuesService;
        this.templateEngine = templateEngine;
        this.pdfRenderer = pdfRenderer;
    }

    public StaticFile render(Report report, int month, int year) {
        if (report.getReportType() == ReportType.MONTH) {
            return renderMonthReport(report, month - 1, year);
        } else {
            return renderYearReport(report, year - 1);
        }
    }

    private StaticFile renderMonthReport(Report report, int month, int year) {
        if (month == 0) {
            month = 12;
            year--;
        }
        final TableValuesDTO tableValues = gatherTableValues(report, month, year, report.getReportFeatures().contains(ReportFeatures.AVERAGES));
        final List<Reading> readings = report.getReportFeatures().contains(ReportFeatures.TEMPERATURE_CURVE) ? List.of(readingService.find(report.getOwner(), year, month)) : List.of();
        final boolean enableTrends = report.getReportFeatures().contains(ReportFeatures.TREND);
        final NewJson data = tableValues.toJson();
        data.setString("month", prependZero(month));
        data.setString("year", String.valueOf(year));
        data.setString("enableTrends", String.valueOf(enableTrends));
        data.setString("temperatures", readings.stream()
                .sorted(Comparator.comparing(Reading::getDate))
                .map(r -> toIsoDateString(r.getDate()) + "," + r.getValue()).collect(Collectors.joining("\n")));
        data.setString("features", report.getReportFeatures().stream().map(Enum::name).map(n -> "\"" + n + "\"").collect(Collectors.joining(",")));

        final StaticFile template = loadTemplate("monthly.typ");
        template.setContent(templateEngine.render(new String(template.getContent()), data).getBytes(StandardCharsets.UTF_8));
        return pdfRenderer.render(template);
    }

    private StaticFile loadTemplate(String template) {
        return lookUpFile("reportTemplates/" + template);
    }

    // copied from Dobby StaticFileService
    private StaticFile lookUpFile(String path) {
        final StaticFile file;

        try (InputStream stream = Main.class.getResourceAsStream("resource/" + path)) {

            if (stream == null) {
                throw new IllegalStateException("Template not found: " + path);
            }

            file = new StaticFile();
            file.setContentType("text/plain");

            try {
                file.setContent(stream.readAllBytes());
                return file;
            } catch (IOException e) {
                LOGGER.error("Error reading file: " + path);
                LOGGER.trace(e);
                throw new IllegalStateException("Error reading file: " + path, e);
            }
        } catch (IOException e) {
            LOGGER.error("Error reading file: " + path);
            LOGGER.trace(e);
            throw new IllegalStateException("Error reading file: " + path, e);
        }
    }

    private TableValuesDTO gatherTableValues(Report report, int month, int year, boolean withAverages) {
        final TableValuesDTO tableValues = new TableValuesDTO();
        final Tupel<Float, Tupel<Float, Float>> temperatureTriple = calculateTemperatureTripleOfMonth(report.getOwner(), month, year);
        tableValues.setTemperatureAverage(temperatureTriple._1());
        tableValues.setTemperatureMax(temperatureTriple._2()._1());
        tableValues.setTemperatureMin(temperatureTriple._2()._2());
        fillTableValuesWithMonthlyValues(tableValues, report, month, year);
        if  (withAverages) {
            fillTableValuesWithAverages(tableValues, report, month, year);
        }

        return tableValues;
    }

    private void fillTableValuesWithAverages(TableValuesDTO tableValues, Report report, int month, int year) {
        final Tupel<Float, Tupel<Float, Float>> temperatureAverages = calculateTemperatureAveragesPreviousMonths(report.getOwner(), month, year);
        tableValues.setAverageTemperatureAverage(temperatureAverages._1());
        tableValues.setAverageTemperatureMax(temperatureAverages._2()._1());
        tableValues.setAverageTemperatureMin(temperatureAverages._2()._2());

        final List<MonthlyValues> previousMonthlyValues = new ArrayList<>();
        boolean foundValues = true;
        while (foundValues) {
            final MonthlyValues monthlyValues = monthlyValuesService.findByOwnerAndYearAndMonth(report.getOwner(), year, month);
            if (monthlyValues == null) {
                foundValues = false;
            } else {
                previousMonthlyValues.add(monthlyValues);
            }
            year--;
        }

        tableValues.setAverageHouseholdPower((float) previousMonthlyValues.stream().mapToDouble(MonthlyValues::getHouseholdPower).average().orElse(0));
        tableValues.setAverageHouseholdWater((float) previousMonthlyValues.stream().mapToDouble(MonthlyValues::getHouseholdWater).average().orElse(0));
        tableValues.setAverageOperatingHoursHeating((float) previousMonthlyValues.stream().mapToDouble(MonthlyValues::getOperatingHoursHeating).average().orElse(0));
        tableValues.setAverageOperatingHoursWater((float) previousMonthlyValues.stream().mapToDouble(MonthlyValues::getOperatingHoursWater).average().orElse(0));
        tableValues.setAverageOperatingHoursTwo((float) previousMonthlyValues.stream().mapToDouble(MonthlyValues::getOperatingHoursTwo).average().orElse(0));
        tableValues.setAverageHighTariffPower((float) previousMonthlyValues.stream().mapToDouble(MonthlyValues::getHighTariffPower).average().orElse(0));
        tableValues.setAverageLowTariffPower((float) previousMonthlyValues.stream().mapToDouble(MonthlyValues::getLowTariffPower).average().orElse(0));
    }

    private void fillTableValuesWithMonthlyValues(TableValuesDTO tableValues, Report report, int month, int year) {
        final MonthlyValues monthlyValues = monthlyValuesService.findByOwnerAndYearAndMonth(report.getOwner(), year, month);
        if (monthlyValues == null) {
            throw new IllegalStateException("No monthly values found for owner " + report.getOwner() + " and month " + month + " and year " + year);
        }

        tableValues.setOperatingHoursHeating(monthlyValues.getOperatingHoursHeating());
        tableValues.setOperatingHoursWater(monthlyValues.getOperatingHoursWater());
        tableValues.setOperatingHoursTwo(monthlyValues.getOperatingHoursTwo());
        tableValues.setHighTariffPower(monthlyValues.getHighTariffPower());
        tableValues.setLowTariffPower(monthlyValues.getLowTariffPower());
        tableValues.setHouseholdPower(monthlyValues.getHouseholdPower());
        tableValues.setHouseholdWater(monthlyValues.getHouseholdWater());
    }

    private Tupel<Float, Tupel<Float, Float>> calculateTemperatureTripleOfMonth(UUID owner, int month, int year) {
        final Reading[] readings = readingService.find(owner, year, month);
        if (readings.length == 0) {
            return new Tupel<>(0f, new Tupel<>(0f, 0f));
        }
        final float average = calculateAverage(List.of(readings));
        final float max = (float) Stream.of(readings).mapToDouble(Reading::getValue).max().orElse(0);
        final float min = (float) Stream.of(readings).mapToDouble(Reading::getValue).min().orElse(0);
        return new Tupel<>(average, new Tupel<>(max, min));
    }

    private Tupel<Float, Tupel<Float, Float>> calculateTemperatureAveragesPreviousMonths(UUID owner, int month, int year) {
        final List<Reading> readings = new ArrayList<>();
        final List<Float> maxValues = new ArrayList<>();
        final List<Float> minValues = new ArrayList<>();
        boolean foundValues = true;
        while (foundValues) {
            final Reading[] batch = readingService.find(owner, year, month);
            if (batch.length == 0) {
                foundValues = false;
            } else {
                readings.addAll(List.of(batch));
                maxValues.add((float) Stream.of(batch).mapToDouble(Reading::getValue).max().orElse(0));
                minValues.add((float) Stream.of(batch).mapToDouble(Reading::getValue).min().orElse(0));
            }
            year--;
        }

        return new Tupel<>(
                calculateAverage(readings),
                new Tupel<>(
                        (float) maxValues.stream().mapToDouble(Float::doubleValue).average().orElse(0),
                        (float) minValues.stream().mapToDouble(Float::doubleValue).average().orElse(0)
                )
        );
    }

    private StaticFile renderYearReport(Report report, int year) {
        final List<MonthlyValues> monthlyValues = gatherMonthlyValuesOfYear(report.getOwner(), year);
        if (monthlyValues == null) {
            throw new IllegalStateException("No monthly values found for owner " + report.getOwner() + " and year " + year);
        }

        final boolean withAverages = report.getReportFeatures().contains(ReportFeatures.AVERAGES);
        final TableValuesDTO tableValues = gatherYearlyTableValues(report, year, monthlyValues, withAverages);
        final List<Reading> readings = report.getReportFeatures().contains(ReportFeatures.TEMPERATURE_CURVE) ? gatherYearlyReadings(report.getOwner(), year) : List.of();
        final boolean enableTrends = report.getReportFeatures().contains(ReportFeatures.TREND);
        final NewJson data = tableValues.toJson();
        data.setString("year", String.valueOf(year));
        data.setString("enableTrends", String.valueOf(enableTrends));
        data.setString("temperatures", readings.stream()
                .sorted(Comparator.comparing(Reading::getDate))
                .map(r -> toIsoDateString(r.getDate()) + "," + r.getValue()).collect(Collectors.joining("\n")));
        data.setString("operatingHoursHeatingCurve", buildMonthlyCurve(monthlyValues, MonthlyValues::getOperatingHoursHeating));
        data.setString("operatingHoursWaterCurve", buildMonthlyCurve(monthlyValues, MonthlyValues::getOperatingHoursWater));
        data.setString("operatingHoursTwoCurve", buildMonthlyCurve(monthlyValues, MonthlyValues::getOperatingHoursTwo));
        data.setString("highTariffPowerCurve", buildMonthlyCurve(monthlyValues, MonthlyValues::getHighTariffPower));
        data.setString("lowTariffPowerCurve", buildMonthlyCurve(monthlyValues, MonthlyValues::getLowTariffPower));
        data.setString("householdPowerCurve", buildMonthlyCurve(monthlyValues, MonthlyValues::getHouseholdPower));
        data.setString("householdWaterCurve", buildMonthlyCurve(monthlyValues, MonthlyValues::getHouseholdWater));
        data.setString("features", report.getReportFeatures().stream().map(Enum::name).map(n -> "\"" + n + "\"").collect(Collectors.joining(",")));

        final StaticFile template = loadTemplate("yearly.typ");
        template.setContent(templateEngine.render(new String(template.getContent()), data).getBytes(StandardCharsets.UTF_8));
        return pdfRenderer.render(template);
    }

    private String buildMonthlyCurve(List<MonthlyValues> monthlyValues, ToIntFunction<MonthlyValues> valueExtractor) {
        final List<String> rows = new ArrayList<>();
        for (int i = 0; i < monthlyValues.size(); i++) {
            rows.add((i + 1) + "," + valueExtractor.applyAsInt(monthlyValues.get(i)));
        }
        return String.join("\n", rows);
    }

    private List<Reading> gatherYearlyReadings(UUID owner, int year) {
        final List<Reading> readings = new ArrayList<>();
        for (int month = 1; month <= 12; month++) {
            readings.addAll(List.of(readingService.find(owner, year, month)));
        }
        return readings;
    }

    private TableValuesDTO gatherYearlyTableValues(Report report, int year, List<MonthlyValues> monthlyValues, boolean withAverages) {
        final TableValuesDTO tableValues = new TableValuesDTO();
        final Tupel<Float, Tupel<Float, Float>> temperatureTriple = calculateTemperatureTripleOfYear(report.getOwner(), year);
        tableValues.setTemperatureAverage(temperatureTriple._1());
        tableValues.setTemperatureMax(temperatureTriple._2()._1());
        tableValues.setTemperatureMin(temperatureTriple._2()._2());
        fillTableValuesWithYearlyValues(tableValues, monthlyValues);
        if (withAverages) {
            fillTableValuesWithYearlyAverages(tableValues, report, year);
        }

        return tableValues;
    }

    private void fillTableValuesWithYearlyAverages(TableValuesDTO tableValues, Report report, int year) {
        final Tupel<Float, Tupel<Float, Float>> temperatureAverages = calculateTemperatureAveragesPreviousYears(report.getOwner(), year);
        tableValues.setAverageTemperatureAverage(temperatureAverages._1());
        tableValues.setAverageTemperatureMax(temperatureAverages._2()._1());
        tableValues.setAverageTemperatureMin(temperatureAverages._2()._2());

        final List<MonthlyValues> previousYearlyValues = new ArrayList<>();
        int previousYear = year - 1;
        boolean foundValues = true;
        while (foundValues) {
            final MonthlyValues yearlySum = sumMonthlyValuesOfYear(report.getOwner(), previousYear);
            if (yearlySum == null) {
                foundValues = false;
            } else {
                previousYearlyValues.add(yearlySum);
            }
            previousYear--;
        }

        tableValues.setAverageHouseholdPower((float) previousYearlyValues.stream().mapToDouble(MonthlyValues::getHouseholdPower).average().orElse(0));
        tableValues.setAverageHouseholdWater((float) previousYearlyValues.stream().mapToDouble(MonthlyValues::getHouseholdWater).average().orElse(0));
        tableValues.setAverageOperatingHoursHeating((float) previousYearlyValues.stream().mapToDouble(MonthlyValues::getOperatingHoursHeating).average().orElse(0));
        tableValues.setAverageOperatingHoursWater((float) previousYearlyValues.stream().mapToDouble(MonthlyValues::getOperatingHoursWater).average().orElse(0));
        tableValues.setAverageOperatingHoursTwo((float) previousYearlyValues.stream().mapToDouble(MonthlyValues::getOperatingHoursTwo).average().orElse(0));
        tableValues.setAverageHighTariffPower((float) previousYearlyValues.stream().mapToDouble(MonthlyValues::getHighTariffPower).average().orElse(0));
        tableValues.setAverageLowTariffPower((float) previousYearlyValues.stream().mapToDouble(MonthlyValues::getLowTariffPower).average().orElse(0));
    }

    private void fillTableValuesWithYearlyValues(TableValuesDTO tableValues, List<MonthlyValues> monthlyValues) {
        tableValues.setOperatingHoursHeating(monthlyValues.stream().mapToInt(MonthlyValues::getOperatingHoursHeating).sum());
        tableValues.setOperatingHoursWater(monthlyValues.stream().mapToInt(MonthlyValues::getOperatingHoursWater).sum());
        tableValues.setOperatingHoursTwo(monthlyValues.stream().mapToInt(MonthlyValues::getOperatingHoursTwo).sum());
        tableValues.setHighTariffPower(monthlyValues.stream().mapToInt(MonthlyValues::getHighTariffPower).sum());
        tableValues.setLowTariffPower(monthlyValues.stream().mapToInt(MonthlyValues::getLowTariffPower).sum());
        tableValues.setHouseholdPower(monthlyValues.stream().mapToInt(MonthlyValues::getHouseholdPower).sum());
        tableValues.setHouseholdWater(monthlyValues.stream().mapToInt(MonthlyValues::getHouseholdWater).sum());
    }

    private MonthlyValues sumMonthlyValuesOfYear(UUID owner, int year) {
        final List<MonthlyValues> monthlyValues = gatherMonthlyValuesOfYear(owner, year);
        if (monthlyValues == null) {
            return null;
        }

        return new MonthlyValues(
                owner,
                new GregorianCalendar(year, Calendar.JANUARY, 1).getTime(),
                monthlyValues.stream().mapToInt(MonthlyValues::getOperatingHoursHeating).sum(),
                monthlyValues.stream().mapToInt(MonthlyValues::getOperatingHoursWater).sum(),
                monthlyValues.stream().mapToInt(MonthlyValues::getOperatingHoursTwo).sum(),
                monthlyValues.stream().mapToInt(MonthlyValues::getHighTariffPower).sum(),
                monthlyValues.stream().mapToInt(MonthlyValues::getLowTariffPower).sum(),
                monthlyValues.stream().mapToInt(MonthlyValues::getHouseholdPower).sum(),
                monthlyValues.stream().mapToInt(MonthlyValues::getHouseholdWater).sum()
        );
    }

    private List<MonthlyValues> gatherMonthlyValuesOfYear(UUID owner, int year) {
        final List<MonthlyValues> monthlyValues = new ArrayList<>();
        for (int month = 1; month <= 12; month++) {
            final MonthlyValues values = monthlyValuesService.findByOwnerAndYearAndMonth(owner, year, month);
            if (values == null) {
                return null;
            }
            monthlyValues.add(values);
        }
        return monthlyValues;
    }

    private Tupel<Float, Tupel<Float, Float>> calculateTemperatureTripleOfYear(UUID owner, int year) {
        final List<Reading> readings = gatherYearlyReadings(owner, year);
        if (readings.isEmpty()) {
            return new Tupel<>(0f, new Tupel<>(0f, 0f));
        }
        final float average = calculateAverage(readings);
        final float max = (float) readings.stream().mapToDouble(Reading::getValue).max().orElse(0);
        final float min = (float) readings.stream().mapToDouble(Reading::getValue).min().orElse(0);
        return new Tupel<>(average, new Tupel<>(max, min));
    }

    private Tupel<Float, Tupel<Float, Float>> calculateTemperatureAveragesPreviousYears(UUID owner, int year) {
        final List<Reading> readings = new ArrayList<>();
        final List<Float> maxValues = new ArrayList<>();
        final List<Float> minValues = new ArrayList<>();
        int previousYear = year - 1;
        boolean foundValues = true;
        while (foundValues) {
            final List<Reading> batch = gatherYearlyReadings(owner, previousYear);
            if (batch.isEmpty()) {
                foundValues = false;
            } else {
                readings.addAll(batch);
                maxValues.add((float) batch.stream().mapToDouble(Reading::getValue).max().orElse(0));
                minValues.add((float) batch.stream().mapToDouble(Reading::getValue).min().orElse(0));
            }
            previousYear--;
        }

        return new Tupel<>(
                calculateAverage(readings),
                new Tupel<>(
                        (float) maxValues.stream().mapToDouble(Float::doubleValue).average().orElse(0),
                        (float) minValues.stream().mapToDouble(Float::doubleValue).average().orElse(0)
                )
        );
    }

    private float calculateAverage(List<Reading> readings) {
        return (float) readings.stream().mapToDouble(Reading::getValue).average().orElse(0);
    }
}