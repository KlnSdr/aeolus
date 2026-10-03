package aeolus.export;

import aeolus.readings.MonthlyValues;
import aeolus.readings.Reading;
import aeolus.readings.TariffPrices;
import aeolus.util.IsoDate;
import dobby.files.StaticFile;
import dobby.util.json.NewJson;
import thot.janus.DataClass;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Export {
    private static final String NEW_LINE = "\n";

    private final List<Reading> readings = new ArrayList<>();
    private final List<MonthlyValues> monthlyValues = new ArrayList<>();
    private final List<TariffPrices> tariffPrices = new ArrayList<>();
    private static final List<String> COMMON_HEADERS = List.of("type", "date");
    private final List<Class<?>> classes = List.of(Reading.class, MonthlyValues.class, TariffPrices.class);

    public void addReading(Reading reading) {
        readings.add(reading);
    }

    public void addMonthlyValues(MonthlyValues monthlyValue) {
        monthlyValues.add(monthlyValue);
    }

    public void addTariffPrices(TariffPrices tariffPrice) {
        tariffPrices.add(tariffPrice);
    }

    public void addAllReadings(List<Reading> readings) {
        this.readings.addAll(readings);
    }

    public void addAllMonthlyValues(List<MonthlyValues> monthlyValues) {
        this.monthlyValues.addAll(monthlyValues);
    }

    public void addAllTariffPrices(List<TariffPrices> tariffPrices) {
        this.tariffPrices.addAll(tariffPrices);
    }

    public String toString() {
        final List<String> lines = new ArrayList<>();
        lines.add(toCSVHeader());
        final List<String> emptyParts = List.of(
                String.join(",", Arrays.stream(toCSVHeader(Reading.class).split(",")).map(s -> "").toList().toArray(new String[0])),
                String.join(",", Arrays.stream(toCSVHeader(MonthlyValues.class).split(",")).map(s -> "").toList().toArray(new String[0])),
                String.join(",", Arrays.stream(toCSVHeader(TariffPrices.class).split(",")).map(s -> "").toList().toArray(new String[0]))
        );

        for (Reading reading : readings) {
            lines.add(
                    "24h," + IsoDate.toIsoDateString(reading.getDate()) + "," +
                    toCSV(reading) + "," + emptyParts.get(1) + "," + emptyParts.get(2)
            );
        }

        for (MonthlyValues monthlyValue : monthlyValues) {
            lines.add(
                    "month," + IsoDate.toIsoDateString(monthlyValue.getDate()).substring(0, 7) + "," +
                    emptyParts.get(0) + "," + toCSV(monthlyValue) + "," + emptyParts.get(2)
            );
        }

        for (TariffPrices tariffPrice : tariffPrices) {
            lines.add(
                    "price," + tariffPrice.getYear() + "," +
                    emptyParts.get(0) + "," + emptyParts.get(1) + "," + toCSV(tariffPrice)
            );
        }

        return String.join(NEW_LINE, lines);
    }

    public StaticFile toCSV() {
        final StaticFile file = new StaticFile();
        file.setContentType("text/csv");
        file.setContent(toString().getBytes(StandardCharsets.UTF_8));

        return file;
    }

    private String toCSV(DataClass data) {
        final NewJson json = data.toJson();
        return switch (data.getClass().getSimpleName()) {
            case "Reading" -> Double.toString((Math.round(json.getFloat("value") * 10) / 10.0));
            case "MonthlyValues" -> String.join(",",
                    Integer.toString(json.getInt("operatingHoursHeating")),
                    Integer.toString(json.getInt("operatingHoursWater")),
                    Integer.toString(json.getInt("operatingHoursTwo")),
                    Integer.toString(json.getInt("highTariffPower")),
                    Integer.toString(json.getInt("lowTariffPower")),
                    Integer.toString(json.getInt("householdPower")),
                    Integer.toString(json.getInt("householdWater"))
            );
            case "TariffPrices" -> String.join(",",
                    Integer.toString(json.getInt("centsHighTariff")),
                    Integer.toString(json.getInt("centsLowTariff")),
                    Integer.toString(json.getInt("centsHouseholdPower"))
            );
            default -> throw new IllegalArgumentException("Unsupported class: " + data.getClass().getSimpleName());
        };
    }

    private String toCSVHeader() {
        StringBuilder headers = new StringBuilder(String.join(",", COMMON_HEADERS));
        for (Class<?> clazz : classes) {
            switch (clazz.getSimpleName()) {
                case "Reading":
                case "MonthlyValues":
                case "TariffPrices":
                    headers.append(",").append(toCSVHeader(clazz));
                    break;
                default:
                    throw new IllegalArgumentException("Unsupported class: " + clazz.getSimpleName());
            }
        }
        return headers.toString();
    }

    private String toCSVHeader(Class<?> clazz) {
        List<String> headers = new ArrayList<>();
        switch (clazz.getSimpleName()) {
            case "Reading":
                headers.add("temperature");
                break;
            case "MonthlyValues":
                headers.addAll(List.of("operatingHoursHeating", "operatingHoursWater", "operatingHoursTwo", "highTariffPower", "lowTariffPower", "householdPower", "householdWater"));
                break;
            case "TariffPrices":
                headers.addAll(List.of("highTariffPrice", "lowTariffPrice", "householdPowerPrice"));
                break;
            default:
                throw new IllegalArgumentException("Unsupported class: " + clazz.getSimpleName());
        }
        return String.join(",", headers);
    }
}