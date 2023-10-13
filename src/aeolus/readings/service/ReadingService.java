package aeolus.readings.service;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;

import java.util.Date;
import java.util.concurrent.ConcurrentHashMap;

import static aeolus.util.IsoDate.*;

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

    public Reading[] find(String from, String to) throws IllegalArgumentException {
        if (!isValidIsoDate(from) || !isValidIsoDate(to)) {
            throw new IllegalArgumentException("Invalid ISO date");
        }
        Date fromDate = parseIsoDate(from);
        Date toDate = parseIsoDate(to);
        return readings.values().stream().filter(reading -> (reading.getDate().after(fromDate) || reading.getDate().equals(fromDate)) && (reading.getDate().before(toDate) || reading.getDate().equals(toDate))).toArray(Reading[]::new);
    }

    public void add(Reading reading) throws DuplicateEntryException {
        Reading savedReading = readings.putIfAbsent(toIsoDateString(reading.getDate()), reading);
        if (savedReading != null) {
            throw new DuplicateEntryException("Reading for date " + toIsoDateString(reading.getDate()) + " already " + "exists");
        }
    }

}
