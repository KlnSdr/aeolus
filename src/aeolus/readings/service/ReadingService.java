package aeolus.readings.service;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

public class ReadingService {
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

    public Reading find(String isoDate) throws IllegalArgumentException, NullPointerException {
        if (!isValidIsoDate(isoDate)) {
            throw new IllegalArgumentException("Invalid ISO date: " + isoDate);
        }
        Reading reading = readings.get(isoDate);
        if (reading == null) {
            throw new NullPointerException("No reading found for date: " + isoDate);
        }
        return reading;
    }

    public void add(Reading reading) throws DuplicateEntryException {
        Reading savedReading = readings.putIfAbsent(toIsoDateString(reading.getDate()), reading);
        if (savedReading != null) {
            throw new DuplicateEntryException("Reading for date " + toIsoDateString(reading.getDate()) + " already exists");
        }
    }

    public static boolean isValidIsoDate(String isoDate) {
        return isoDate == null || Pattern.matches("\\d{4}-\\d{2}-\\d{2}", isoDate);
    }

    private String toIsoDateString(Date date) {
        DateFormat format = new SimpleDateFormat("yyyy-MM-dd");
        return format.format(date);
    }
}
