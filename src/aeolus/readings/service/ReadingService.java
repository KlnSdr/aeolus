package aeolus.readings.service;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.util.json.NewJson;
import thot.connector.IConnector;
import thot.janus.Janus;

import java.util.UUID;

import static aeolus.util.IsoDate.toIsoDateString;
import static hades.common.Util.prependZero;

@RegisterFor(ReadingService.class)
public class ReadingService {
    public static final String bucketName = "aeolus_temperatureReadings";
    private final IConnector connector;

    @Inject
    public ReadingService(IConnector connector) {
        this.connector = connector;
    }

    public Reading[] find(UUID owner, int year) {
        return find(owner, year + "-[0-9][0-9]-[0-9][0-9]");
    }

    public Reading[] find(UUID owner, int year, int month) throws IllegalArgumentException {
        if (month < 1 || month > 12) {
            throw new IllegalArgumentException("Invalid month: " + month);
        }

        return find(owner, year + "-" + prependZero(month) + "-[0-9][0-9]");
    }

    public Reading find(UUID owner, int year, int month, int day) throws IllegalArgumentException, NullPointerException {
        if (month < 1 || month > 12) {
            throw new IllegalArgumentException("Invalid month: " + month);
        }
        if (day < 1 || day > 31) {
            throw new IllegalArgumentException("Invalid day: " + day);
        }
        String yearString = Integer.toString(year);
        String monthString = prependZero(month);
        String dayString = prependZero(day);

        String key = owner + "_" + yearString + "-" + monthString + "-" + dayString;

        final Reading reading = Janus.parse(connector.read(bucketName, key, NewJson.class), Reading.class);

        if (reading == null) {
            throw new NullPointerException("No reading found for date: " + key);
        }
        return reading;
    }

    private Reading[] find(UUID owner, String pattern) {
        final NewJson[] readingsJson = connector.readPattern(bucketName, owner + "_" + pattern, NewJson.class);

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
        final NewJson existingReading = connector.read(bucketName, reading.getKey(), NewJson.class);
        if (existingReading != null) {
            throw new DuplicateEntryException("Reading for date " + toIsoDateString(reading.getDate()) + " already " + "exists");
        }

        return connector.write(bucketName, reading.getKey(), reading.toStoreJson());
    }

}
