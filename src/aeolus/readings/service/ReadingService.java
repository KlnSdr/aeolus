package aeolus.readings.service;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;
import dobby.util.json.NewJson;
import janus.Janus;
import thot.connector.Connector;

import static aeolus.util.IsoDate.toIsoDateString;

public class ReadingService {
    public static final String bucketName = "aeolus_temperatureReadings";
    private static ReadingService instance;

    private ReadingService() {
    }

    public static ReadingService getInstance() {
        if (instance == null) {
            instance = new ReadingService();
        }
        return instance;
    }

    public Reading[] find(int year) {
        return find(year + "-[0-9][0-9]-[0-9][0-9]");
    }

    public Reading[] find(int year, int month) throws IllegalArgumentException {
        if (month < 1 || month > 12) {
            throw new IllegalArgumentException("Invalid month: " + month);
        }

        if (month < 10) {
            return find(year + "-0" + month + "-[0-9][0-9]");
        }
        return find(year + "-" + month + "-[0-9][0-9]");
    }

    public Reading find(int year, int month, int day) throws IllegalArgumentException, NullPointerException {
        if (month < 1 || month > 12) {
            throw new IllegalArgumentException("Invalid month: " + month);
        }
        if (day < 1 || day > 31) {
            throw new IllegalArgumentException("Invalid day: " + day);
        }
        String yearString = Integer.toString(year);
        String monthString = month < 10 ? "0" + month : Integer.toString(month);
        String dayString = day < 10 ? "0" + day : Integer.toString(day);

        String key = yearString + "-" + monthString + "-" + dayString;

        final Reading reading = Janus.parse(Connector.read(bucketName, key, NewJson.class), Reading.class);

        if (reading == null) {
            throw new NullPointerException("No reading found for date: " + key);
        }
        return reading;
    }

    private Reading[] find(String pattern) {
        final NewJson[] readingsJson = Connector.readPattern(bucketName, pattern, NewJson.class);

        if (readingsJson == null) {
            return new Reading[0];
        }

        final Reading[] readings = new Reading[readingsJson.length];
        for (int i = 0; i < readings.length; i++) {
            readings[i] = Janus.parse(readingsJson[i], Reading.class);
        }

        return readings;
    }

    public boolean add(Reading reading) throws DuplicateEntryException {
        final NewJson existingReading = Connector.read(bucketName, reading.getKey(), NewJson.class);
        if (existingReading != null) {
            throw new DuplicateEntryException("Reading for date " + toIsoDateString(reading.getDate()) + " already " + "exists");
        }

        return Connector.write(bucketName, reading.getKey(), reading.toStoreJson());
    }

}
