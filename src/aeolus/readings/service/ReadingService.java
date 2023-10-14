package aeolus.readings.service;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;

import java.io.Serializable;
import java.util.Date;
import java.util.concurrent.ConcurrentHashMap;

import static aeolus.util.IsoDate.*;

public class ReadingService {
    private static ReadingService instance;
    private final ConcurrentHashMap<String, Reading> readings = new ConcurrentHashMap<>();
    private static final String bucketName = "temperatureReadings";

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
        Reading reading = thot.connector.Connector.read(bucketName, isoDate, Reading.class);
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
        boolean wasSaved = thot.connector.Connector.write(bucketName, toIsoDateString(reading.getDate()), reading);
        if (!wasSaved) {
            throw new DuplicateEntryException("Reading for date " + toIsoDateString(reading.getDate()) + " already " + "exists");
        }
    }

}
