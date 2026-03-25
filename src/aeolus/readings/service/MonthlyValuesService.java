package aeolus.readings.service;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.MonthlyValues;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.util.json.NewJson;
import thot.connector.IConnector;
import thot.janus.Janus;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static aeolus.util.IsoDate.toIsoDateString;
import static hades.common.Util.prependZero;

@RegisterFor(MonthlyValuesService.class)
public class MonthlyValuesService {
    public static String BUCKET_NAME = "aeolus_monthlyValues";
    private final IConnector connector;

    @Inject
    public MonthlyValuesService(IConnector connector) {
        this.connector = connector;
    }

    public MonthlyValues[] findByOwner(UUID owner) {
        final NewJson[] jsonResults = connector.readPattern(BUCKET_NAME, owner + "_[0-9][0-9][0-9][0-9]-[0-1][0-9]", NewJson.class);
        final List<MonthlyValues> results = new ArrayList<>();
        for (NewJson json : jsonResults) {
            if (json != null) {
                results.add(Janus.parse(json, MonthlyValues.class));
            }
        }
        return results.toArray(new MonthlyValues[0]);
    }

    public MonthlyValues[] findByOwnerAndYear(UUID owner, int year) {
        final NewJson[] jsonResults = connector.readPattern(BUCKET_NAME, owner + "_" + year + "-[0-1][0-9]", NewJson.class);
        final List<MonthlyValues> results = new ArrayList<>();
        for (NewJson json : jsonResults) {
            if (json != null) {
                results.add(Janus.parse(json, MonthlyValues.class));
            }
        }
        return results.toArray(new MonthlyValues[0]);
    }

    public MonthlyValues[] findByOwnerAndMonth(UUID owner, int month) {
        final NewJson[] jsonResults = connector.readPattern(BUCKET_NAME, owner + "_[0-9][0-9][0-9][0-9]-" + prependZero(month), NewJson.class);
        final List<MonthlyValues> results = new ArrayList<>();
        for (NewJson json : jsonResults) {
            if (json != null) {
                results.add(Janus.parse(json, MonthlyValues.class));
            }
        }
        return results.toArray(new MonthlyValues[0]);
    }

    public MonthlyValues[] findByOwnerAndYearAndMonth(UUID owner, int year, int month) {
        final NewJson[] jsonResults = connector.readPattern(BUCKET_NAME, owner + "_" + year + "-" + prependZero(month), NewJson.class);
        final List<MonthlyValues> results = new ArrayList<>();
        for (NewJson json : jsonResults) {
            if (json != null) {
                results.add(Janus.parse(json, MonthlyValues.class));
            }
        }
        return results.toArray(new MonthlyValues[0]);
    }

    public boolean update(MonthlyValues values) throws DuplicateEntryException {
        final NewJson existingReading = connector.read(BUCKET_NAME, values.getKey(), NewJson.class);
        if (existingReading != null) {
            throw new DuplicateEntryException("Monthly values already exist for date: " + toIsoDateString(values.getDate()).substring(0, 7));
        }
        return connector.write(BUCKET_NAME, values.getKey(), values.toJson());
    }
}
