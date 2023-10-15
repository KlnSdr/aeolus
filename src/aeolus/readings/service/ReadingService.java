package aeolus.readings.service;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;

import java.util.concurrent.ConcurrentHashMap;

import static aeolus.util.IsoDate.isValidIsoDate;
import static aeolus.util.IsoDate.toIsoDateString;

public class ReadingService {
    private static final String bucketName = "temperatureReadings";
    private static ReadingService instance;
    private final ConcurrentHashMap<String, Reading> readings = new ConcurrentHashMap<>();

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
        Reading reading = thot.connector.Connector.read(bucketName, key, Reading.class);
        if (reading == null) {
            throw new NullPointerException("No reading found for date: " + key);
        }
        return reading;
    }

    private Reading[] find(String pattern) {
        Reading[] reading = thot.connector.Connector.readPattern(bucketName, pattern, Reading.class);
        if (reading == null) {
            return new Reading[0];
        }
        return reading;
    }

    public boolean add(Reading reading) throws DuplicateEntryException {
        Reading existingReading = thot.connector.Connector.read(bucketName, toIsoDateString(reading.getDate()), Reading.class);
        if (existingReading != null) {
            throw new DuplicateEntryException("Reading for date " + toIsoDateString(reading.getDate()) + " already " + "exists");
        }

        return thot.connector.Connector.write(bucketName, toIsoDateString(reading.getDate()), reading);
    }

}
