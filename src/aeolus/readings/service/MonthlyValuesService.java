package aeolus.readings.service;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.MonthlyValues;
import aeolus.readings.Reading;
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
    public static String BUCKET_NAME_PREVIOUS_CUMULATIVE = "aeolus_monthlyValues_previous_cumulative";
    public static String BUCKET_NAME_TEMPORARY = "aeolus_monthlyValues_temporary";
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

    public MonthlyValues findByOwnerAndYearAndMonth(UUID owner, int year, int month) {
        return Janus.parse(connector.read(BUCKET_NAME, owner + "_" + year + "-" + prependZero(month), NewJson.class), MonthlyValues.class);
    }

    public boolean update(MonthlyValues values) throws DuplicateEntryException {
        final NewJson existingReading = connector.read(BUCKET_NAME, values.getKey(), NewJson.class);
        if (existingReading != null) {
            throw new DuplicateEntryException("Monthly values already exist for date: " + toIsoDateString(values.getDate()).substring(0, 7));
        }
        return connector.write(BUCKET_NAME, values.getKey(), values.toJson());
    }

    public MonthlyValues calculateMonthsValuesFromCumulativeAndUpdateDatabase(MonthlyValues cumulative) throws DuplicateEntryException {
        final MonthlyValues checkIfAlreadyExists = findByOwnerAndYearAndMonth(cumulative.getOwner(), cumulative.getDate().getYear(), cumulative.getDate().getMonth() + 1);
        if  (checkIfAlreadyExists != null) {
            throw new DuplicateEntryException("Monthly values already exist for date: " + toIsoDateString(cumulative.getDate()).substring(0, 7));
        }

        final MonthlyValues newValues;
        final MonthlyValues previousCumulative = getLastCumulative(cumulative.getOwner());
        final MonthlyValues temporary = getTemporary(cumulative.getOwner());

        if (previousCumulative != null && temporary != null) {
            newValues = add(subtract(prepareTemporaryAndFillUnusedSlots(cumulative, temporary, previousCumulative), previousCumulative), cumulative);
        } else if (previousCumulative == null && temporary != null) {
            newValues = add(prepareTemporaryAndFillUnusedSlots(cumulative, temporary, null), cumulative);
        } else if (previousCumulative != null) {
            newValues = subtract(cumulative, previousCumulative);
        } else {
            newValues = cumulative;
        }

        newValues.setDate(cumulative.getDate());
        if (!updateLastCumulative(cumulative)) {
            throw new IllegalStateException("Monthly values could not be calculated");
        }
        if (temporary != null && !removeTemporary(temporary)) {
            throw new IllegalStateException("Monthly values could not be calculated");
        }
        return newValues;
    }

    private MonthlyValues prepareTemporaryAndFillUnusedSlots(MonthlyValues cumulative, MonthlyValues temporary, MonthlyValues previous) {
        if (previous == null) {
            return new MonthlyValues(
                    cumulative.getOwner(),
                    cumulative.getDate(),
                    temporary.getOperatingHoursHeating() == -1 ? cumulative.getOperatingHoursHeating() : temporary.getOperatingHoursHeating(),
                    temporary.getOperatingHoursWater() == -1 ? cumulative.getOperatingHoursWater() : temporary.getOperatingHoursWater(),
                    temporary.getOperatingHoursTwo() == -1 ? cumulative.getOperatingHoursTwo() : temporary.getOperatingHoursTwo(),
                    temporary.getHighTariffPower() == -1 ? cumulative.getHighTariffPower() : temporary.getHighTariffPower(),
                    temporary.getLowTariffPower() == -1 ? cumulative.getLowTariffPower() : temporary.getLowTariffPower(),
                    temporary.getHouseholdPower() == -1 ? cumulative.getHouseholdPower() : temporary.getHouseholdPower(),
                    temporary.getHouseholdWater() == -1 ? cumulative.getHouseholdWater() : temporary.getHouseholdWater()
            );
        } else {
            return new MonthlyValues(
                    cumulative.getOwner(),
                    cumulative.getDate(),
                    temporary.getOperatingHoursHeating() == -1 ? 0 : temporary.getOperatingHoursHeating(),
                    temporary.getOperatingHoursWater() == -1 ? 0 : temporary.getOperatingHoursWater(),
                    temporary.getOperatingHoursTwo() == -1 ? 0 : temporary.getOperatingHoursTwo(),
                    temporary.getHighTariffPower() == -1 ? 0 : temporary.getHighTariffPower(),
                    temporary.getLowTariffPower() == -1 ? 0 : temporary.getLowTariffPower(),
                    temporary.getHouseholdPower() == -1 ? 0 : temporary.getHouseholdPower(),
                    temporary.getHouseholdWater() == -1 ? 0 : temporary.getHouseholdWater()
            );
        }
    }

    private MonthlyValues getLastCumulative(UUID owner) {
        return Janus.parse(connector.read(BUCKET_NAME_PREVIOUS_CUMULATIVE, owner.toString(), NewJson.class), MonthlyValues.class);
    }

    private MonthlyValues getTemporary(UUID owner) {
        return Janus.parse(connector.read(BUCKET_NAME_TEMPORARY, owner.toString(), NewJson.class), MonthlyValues.class);
    }

    private boolean updateLastCumulative(MonthlyValues values) {
        return connector.write(BUCKET_NAME_PREVIOUS_CUMULATIVE, values.getOwner().toString(), values.toJson());
    }

    public boolean updateTemporary(MonthlyValues values) {
        return connector.write(BUCKET_NAME_TEMPORARY, values.getOwner().toString(), values.toJson());
    }

    private boolean removeTemporary(MonthlyValues values) {
        return connector.delete(BUCKET_NAME_TEMPORARY, values.getOwner().toString());
    }

    /// a + b = c
    private MonthlyValues add(MonthlyValues a,  MonthlyValues b) {
        return new MonthlyValues(
                a.getOwner(),
                a.getDate(),
                a.getOperatingHoursHeating() + b.getOperatingHoursHeating(),
                a.getOperatingHoursWater() + b.getOperatingHoursWater(),
                a.getOperatingHoursTwo() + b.getOperatingHoursTwo(),
                a.getHighTariffPower() + b.getHighTariffPower(),
                a.getLowTariffPower() + b.getLowTariffPower(),
                a.getHouseholdPower() + b.getHouseholdPower(),
                a.getHouseholdWater() + b.getHouseholdWater()
        );
    }

    /// a - b = c
    private MonthlyValues subtract(MonthlyValues a,  MonthlyValues b) {
        return new MonthlyValues(
                a.getOwner(),
                a.getDate(),
                a.getOperatingHoursHeating() - b.getOperatingHoursHeating(),
                a.getOperatingHoursWater() - b.getOperatingHoursWater(),
                a.getOperatingHoursTwo() - b.getOperatingHoursTwo(),
                a.getHighTariffPower() - b.getHighTariffPower(),
                a.getLowTariffPower() - b.getLowTariffPower(),
                a.getHouseholdPower() - b.getHouseholdPower(),
                a.getHouseholdWater() - b.getHouseholdWater()
        );
    }
}
